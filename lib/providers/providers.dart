import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app_v2_final/models/aggregated_stats_model.dart';
import 'package:focus_app_v2_final/models/chat_model.dart';
import 'package:focus_app_v2_final/models/lesson_model.dart';
import 'package:focus_app_v2_final/models/plan_model.dart';
import 'package:focus_app_v2_final/models/topic_model.dart';
import 'package:focus_app_v2_final/models/user_model.dart';
import 'package:focus_app_v2_final/repositories/plan_repository.dart';
import 'package:focus_app_v2_final/repositories/user_repository.dart';
import 'package:focus_app_v2_final/services/auth_service.dart';
import 'package:focus_app_v2_final/services/authorization_service.dart';
import 'package:focus_app_v2_final/services/firestore_service.dart';

// --- TEMEL SERVİS PROVIDER'LARI ---

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(firebaseAuth: ref.watch(firebaseAuthProvider));
});
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(firestore: ref.watch(firebaseFirestoreProvider));
});
final authorizationServiceProvider = Provider<AuthorizationService>((ref) => AuthorizationService());

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(firestore: ref.watch(firebaseFirestoreProvider));
});
final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository(firestore: ref.watch(firebaseFirestoreProvider));
});


// --- AUTHENTICATION (KİMLİK DOĞRULAMA) PROVIDERS ---

final authStateChangesProvider = StreamProvider.autoDispose<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        // Kullanıcı giriş yapmış, Firestore'dan kullanıcı belgesini dinle
        return ref.read(userRepositoryProvider).getUserStream(user.uid);
      } else {
        // Kullanıcı giriş yapmamış, null değer içeren bir stream döndür
        return Stream.value(null);
      }
    },
    loading: () {
      // Auth durumu yükleniyor, boş bir stream döndür
      return const Stream.empty();
    },
    error: (error, stackTrace) {
      // Auth durumunda hata oluştu, hata içeren bir stream döndür
      return Stream.error('Authentication error: $error');
    },
  );
});


// --- DATA (VERİ) PROVIDERS ---

final studentsForCoachProvider = StreamProvider.autoDispose.family<List<UserModel>, String>((ref, coachId) {
  return ref.watch(userRepositoryProvider).getStudentsForCoach(coachId);
});

final assignedCoachProvider = FutureProvider.autoDispose.family<UserModel?, String>((ref, coachId) {
  return ref.watch(userRepositoryProvider).getUserById(coachId);
});

final todaysPlansProvider = StreamProvider.autoDispose.family<List<PlanModel>, String>((ref, studentId) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  return ref.watch(planRepositoryProvider).getPlansForStudent(studentId, startOfDay, endOfDay);
});

final weekPlansProvider = StreamProvider.autoDispose.family<List<PlanModel>, ({String studentId, DateTime weekDate})>((ref, params) {
  final startOfWeek = params.weekDate.subtract(Duration(days: params.weekDate.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));
  return ref.watch(planRepositoryProvider).getPlansForStudent(params.studentId, startOfWeek, endOfWeek);
});

final lessonsForUserProvider = FutureProvider.autoDispose<List<LessonModel>>((ref) {
  final userAsyncValue = ref.watch(currentUserProvider);

  return userAsyncValue.when(
    data: (userModel) {
      if (userModel == null || userModel.examType == null || userModel.examType!.isEmpty) {
        return [];
      }
      return ref.read(planRepositoryProvider).getLessonsForExam(userModel.examType!);
    },
    error: (err, stack) {
      debugPrint('lessonsForUserProvider Hatası: $err');
      return [];
    },
    loading: () => [],
  );
});

final topicsForLessonProvider = FutureProvider.autoDispose
    .family<List<TopicModel>, ({String examId, String lessonId})>((ref, params) {
  return ref.watch(planRepositoryProvider).getTopicsForLesson(params.examId, params.lessonId);
});

// --- DEĞİŞTİRİLMEMİŞ PROVIDER'LAR ---

final studentStatsProvider = StreamProvider.autoDispose
    .family<List<AggregatedStatsModel>, String>((ref, studentId) {
  return ref.watch(firestoreServiceProvider).getAggregatedStatsForStudent(studentId);
});

final chatsProvider = StreamProvider.autoDispose.family<List<ChatModel>, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).getChatsStream(userId);
});
