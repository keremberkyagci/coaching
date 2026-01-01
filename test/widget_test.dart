// DOSYA YOLU: test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_app_v2_final/models/user_model.dart';
import 'package:focus_app_v2_final/providers/providers.dart';
import 'package:focus_app_v2_final/screens/coach_dashboard_screen.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks/mock_services.dart';

void main() {
  late MockAuthService mockAuthService;
  late MockFirestoreService mockFirestoreService;
  late MockUserRepository mockUserRepository; // YENİ
  late MockAuthorizationService mockAuthorizationService;
  late MockUser mockUser;

  setUpAll(() {
    registerFallbackValue(FakeUser());
    registerFallbackValue(FakeUserModel());
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockFirestoreService = MockFirestoreService();
    mockUserRepository = MockUserRepository(); // YENİ
    mockAuthorizationService = MockAuthorizationService();
    mockUser = MockUser(uid: 'coach_mock_uid');

    when(() => mockAuthService.currentUser).thenReturn(mockUser);
    when(() => mockAuthService.authStateChanges)
        .thenAnswer((_) => Stream.value(mockUser));
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
        firestoreServiceProvider.overrideWithValue(mockFirestoreService),
        userRepositoryProvider.overrideWithValue(mockUserRepository), // YENİ
        authorizationServiceProvider.overrideWithValue(mockAuthorizationService),
      ],
      child: const MaterialApp(
        home: CoachDashboardScreen(),
      ),
    );
  }

  group('CoachDashboardScreen Widget Testleri', () {
    testWidgets('veri yüklenirken CircularProgressIndicator gösterir',
        (WidgetTester tester) async {
      when(() => mockUserRepository.getStudentsForCoach(any())) // GÜNCELLENDİ
          .thenAnswer((_) => const Stream.empty());
      
      await tester.pumpWidget(createTestWidget());
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('öğrenci listesi boş olduğunda bilgilendirme mesajı gösterir',
        (WidgetTester tester) async {
      when(() => mockUserRepository.getStudentsForCoach(any())) // GÜNCELLENDİ
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Henüz bağlı öğrenciniz yok.'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('öğrenci listesi dolu olduğunda öğrencileri listeler',
        (WidgetTester tester) async {
      final mockStudents = [
        const UserModel(
            id: 'student1',
            name: 'Ahmet Yılmaz',
            email: 'ahmet@test.com',
            userType: UserType.student,
            examType: 'YKS',
            subscriptionTier: SubscriptionTier.free),
        const UserModel(
            id: 'student2',
            name: 'Ayşe Kaya',
            email: 'ayse@test.com',
            userType: UserType.student,
            examType: 'LGS',
            subscriptionTier: SubscriptionTier.premium),
      ];

      when(() => mockUserRepository.getStudentsForCoach(any())) // GÜNCELLENDİ
          .thenAnswer((_) => Stream.value(mockStudents));
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ahmet Yılmaz'), findsOneWidget);
      expect(find.text('Ayşe Kaya'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
    });
  });
}
