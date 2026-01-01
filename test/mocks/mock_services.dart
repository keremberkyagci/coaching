import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:focus_app_v2_final/models/user_model.dart';
import 'package:focus_app_v2_final/repositories/user_repository.dart';
import 'package:focus_app_v2_final/services/auth_service.dart';
import 'package:focus_app_v2_final/services/authorization_service.dart';
import 'package:focus_app_v2_final/services/firestore_service.dart';
import 'package:mocktail/mocktail.dart';

// --- MOCK SINIFLAR ---
class MockAuthService extends Mock implements AuthService {}
class MockFirestoreService extends Mock implements FirestoreService {}
class MockUserRepository extends Mock implements UserRepository {}
class MockAuthorizationService extends Mock implements AuthorizationService {}

// Gerçek User sınıfını taklit eden sahte bir sınıf
class MockUser extends Mock implements auth.User {
  final String _uid;
  MockUser({String uid = 'mock_uid'}) : _uid = uid;

  @override
  String get uid => _uid;
}

// --- FAKE SINIFLAR (FALLBACK İÇİN) ---
// Mocktail'in `registerFallbackValue` metodu için sahte (fake) sınıflar.
// Argümanların tipini eşleştirmek için kullanılır.

class FakeUser extends Fake implements auth.User {}

class FakeUserModel extends Fake implements UserModel {}
