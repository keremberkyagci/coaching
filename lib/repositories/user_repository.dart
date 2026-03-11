import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // debugPrint için eklendi
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _db;

  UserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<UserModel> get usersRef =>
      _db.collection('users').withConverter<UserModel>(
            fromFirestore: UserModel.fromFirestore,
            toFirestore: (UserModel model, options) => model.toFirestore(),
          );

  Future<void> addUser(UserModel user) async {
    await usersRef.doc(user.id).set(user);
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await usersRef.doc(userId).update(data);
  }
  
  Future<void> assignCoachToStudent(String studentId, String coachId) async {
    final coachDoc = await usersRef.doc(coachId).get();

    if (!coachDoc.exists) {
      throw Exception('Bu ID ile bir kullanıcı bulunamadı.');
    }

    final coachData = coachDoc.data();
    if (coachData == null || coachData.userType != UserType.coach) {
      throw Exception('Bu ID bir koça ait değil.');
    }

    // Hem 'coachId' alanını güncelliyoruz, hem de coach_dashboard_service'in
    // kullandığı 'coachConnection' objesini approved olarak ayarlıyoruz.
    await usersRef.doc(studentId).update({
      'coachId': coachId,
      'coachConnection': {
        'coachId': coachId,
        'status': 'approved'
      }
    });
  }

  Future<UserModel?> getUserById(String userId) async {
    // Sadece cache üzerinden okumak yerine sunucudan en güncel veriyi çekiyoruz.
    // Çünkü cache'de veri yoksa 'null' dönüp UI tarafında hataya sebep oluyordu.
    try {
      final docSnapshot = await usersRef.doc(userId).get();
      return docSnapshot.data();
    } catch (e) {
      debugPrint("getUserById hatası: $e");
      return null;
    }
  }

  Stream<UserModel?> getUserStream(String uid) {
    debugPrint("--- USER REPO DEBUG: getUserStream METODU ÇAĞRILDI, UID: $uid ---");
    final docStream = usersRef.doc(uid).snapshots();
    return docStream.map((snapshot) {
      debugPrint("--- USER REPO DEBUG: Firestore'dan snapshot GELDİ. Snapshot var mı: ${snapshot.exists} ---");
      if (snapshot.exists && snapshot.data() != null) {
        final user = snapshot.data();
        debugPrint("--- USER REPO DEBUG: Kullanıcı verisi başarıyla map'lendi: ${user?.name} ---");
        return user;
      }
      debugPrint("--- USER REPO DEBUG: Snapshot yok veya veri null. Null döndürülüyor. ---");
      return null;
    });
  }

  Stream<List<UserModel>> getStudentsForCoach(String coachId) {
    return usersRef
        .where('userType', isEqualTo: UserType.student.name)
        .where('coachId', isEqualTo: coachId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Stream<List<UserModel>> getAllUsersStream(String currentUserId) {
    return usersRef
        .where('id', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
