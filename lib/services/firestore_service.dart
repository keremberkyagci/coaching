// ============================================================
// lib/services/firestore_service.dart — Genel Firestore erişim servisi
//
// Temel CRUD işlemleri + chat sistemi + istatistik operasyonları burada toplanmıştır:
//   - getDocument / addDocument / updateDocument / deleteDocument : Generic CRUD
//   - chatsRef / getMessagesRef / getAggregatedStatsRef           : TypedRef converter'lar
//   - getChatsStream / getChatMessagesStream                       : Gerçek zamanlı listeler
//   - getOrCreateChat : İki kullanıcı arasında sohbet odasını bul ya da yarat
//   - sendMessage     : Mesaj gönder ve sohbeti güncelle
//   - markMessagesAsRead : Okunmamış mesajları toplu okundu işaretle (Firestore batch)
//
// NOT: Eski manuel "_cache" mekanizması kaldırılmıştır.
//      Firestore kendi offline cache'ini otomatik yönetir.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/aggregated_stats_model.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // FirestoreService içinde yer alan manuel "_cache" mekanizmasını sildik.
  // Firebase Firestore arka planda kendi offline cache sistemini zaten mükemmel yönetir.

  Future<Map<String, dynamic>?> getDocument(
    String collectionPath,
    String documentId, {
    bool forceRefresh = false,
  }) async {
    // GetOptions ile eğer zorunlu yenileme istenirse Server'dan, yoksa default davranış ile veriyi çekiyoruz.
    final doc = await _db.collection(collectionPath).doc(documentId).get(
          GetOptions(
              source: forceRefresh ? Source.server : Source.serverAndCache),
        );

    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  Future<String> addDocument(
      String collectionPath, Map<String, dynamic> data) async {
    final docRef = await _db.collection(collectionPath).add(data);
    return docRef.id;
  }

  Future<void> updateDocument(String collectionPath, String documentId,
      Map<String, dynamic> data) async {
    await _db.collection(collectionPath).doc(documentId).update(data);
  }

  Future<void> deleteDocument(String collectionPath, String documentId) async {
    await _db.collection(collectionPath).doc(documentId).delete();
  }

  CollectionReference<AggregatedStatsModel> getAggregatedStatsRef(
          String studentId) =>
      _db
          .collection('users')
          .doc(studentId)
          .collection('aggregatedStats')
          .withConverter<AggregatedStatsModel>(
            fromFirestore: AggregatedStatsModel.fromFirestore,
            toFirestore: (AggregatedStatsModel model, _) => model.toFirestore(),
          );

  Stream<List<AggregatedStatsModel>> getAggregatedStatsForStudent(
      String studentId) {
    return getAggregatedStatsRef(studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<AggregatedStatsModel>> fetchAggregatedStatsForStudent(
      String studentId) async {
    final snapshot = await getAggregatedStatsRef(studentId).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
