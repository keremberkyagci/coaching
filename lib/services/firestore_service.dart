import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/aggregated_stats_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

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
      GetOptions(source: forceRefresh ? Source.server : Source.serverAndCache),
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

  CollectionReference<ChatModel> get chatsRef =>
      _db.collection('chats').withConverter<ChatModel>(
            fromFirestore: (snapshot, _) => ChatModel.fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (ChatModel model, options) => model.toMap(),
          );

  CollectionReference<MessageModel> getMessagesRef(String chatId) => _db
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .withConverter<MessageModel>(
        fromFirestore: MessageModel.fromFirestore,
        toFirestore: (MessageModel model, options) => model.toFirestore(),
      );

  CollectionReference<AggregatedStatsModel> getAggregatedStatsRef(String studentId) =>
      _db.collection('users').doc(studentId).collection('aggregatedStats').withConverter<AggregatedStatsModel>(
            fromFirestore: AggregatedStatsModel.fromFirestore,
            toFirestore: (AggregatedStatsModel model, _) => model.toFirestore(),
          );

  Stream<List<ChatModel>> getChatsStream(String userId) {
    return chatsRef
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<String> getOrCreateChat(String currentUserId, String otherUserId) async {
    final querySnapshot = await chatsRef
        .where('participants', arrayContains: currentUserId)
        .get();

    final existingChat = querySnapshot.docs.where((doc) {
      final participants = List<String>.from(doc.data().participants);
      return participants.contains(otherUserId);
    }).firstOrNull;

    if (existingChat != null) {
      return existingChat.id;
    } else {
      final newChat = ChatModel(
        id: '',
        participants: [currentUserId, otherUserId],
        participantDetails: const {},
        lastMessage: 'Sohbet başlatıldı.',
        lastMessageTimestamp: Timestamp.now(),
        lastMessageSenderId: '',
        unreadCounts: {currentUserId: 0, otherUserId: 0},
        lastRead: const {},
      );
      final docRef = await chatsRef.add(newChat);
      return docRef.id;
    }
  }

  Stream<List<MessageModel>> getChatMessagesStream(String chatId) {
    return getMessagesRef(chatId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }


  Stream<List<AggregatedStatsModel>> getAggregatedStatsForStudent(String studentId) {
    return getAggregatedStatsRef(studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> sendMessage(String chatId, MessageModel message, UserModel sender) async {
    await getMessagesRef(chatId).add(message);

    final chatUpdateData = {
      'lastMessage': message.text,
      'lastMessageTimestamp': message.timestamp,
      'lastMessageSenderId': message.senderId,
      'participantDetails.${sender.id}.displayName': sender.name,
      'participantDetails.${sender.id}.profileImageUrl': sender.profileImageUrl,
    };

    await chatsRef.doc(chatId).update(chatUpdateData);
  }
  
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    final querySnapshot = await getMessagesRef(chatId)
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return;
    }

    final batch = _db.batch();

    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
    debugPrint('${querySnapshot.docs.length} adet mesaj okundu olarak işaretlendi.');
  }
}
