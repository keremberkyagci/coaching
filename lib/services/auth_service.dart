import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;

  // GÜNCELLENDİ: Artık FirebaseAuth'ı dışarıdan alıyor.
  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  // Mevcut kullanıcıyı getiren getter
  User? get currentUser => _firebaseAuth.currentUser;

  // Auth state değişikliklerini dinleyen stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // E-posta ve şifre ile kullanıcı kaydı
  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // E-posta ve şifre ile kullanıcı girişi
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Çıkış yapma
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Şifre sıfırlama e-postası gönderme
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
