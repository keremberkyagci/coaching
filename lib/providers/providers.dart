// ============================================================
// lib/providers/providers.dart — Uygulamanın merkezi state yönetimi
//
// Riverpod ile tüm provider'lar tek dosyada tanımlanmıştır.
// Katmanlar (yukarıdan aşağıya):
//   1. Firebase bağımlılıkları (FirebaseFirestore, FirebaseAuth)
//   2. Servisler (AuthService, FirestoreService)
//   3. Repository'ler (UserRepository, PlanRepository)
//   4. Auth state (kim giriş yapmış? → UserModel stream)
//   5. Veri provider'ları (planlar, dersler, mesajlar, istatistikler)
//
// Kullanım: ref.watch(providerAdı) → veriye abone ol
//           ref.read(providerAdı)  → bir kez oku / metod çağır
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app_v2_final/models/aggregated_stats_model.dart';
import 'package:focus_app_v2_final/models/lesson_model.dart';
import 'package:focus_app_v2_final/models/plan_model.dart';
import 'package:focus_app_v2_final/models/study_session_model.dart';
import 'package:focus_app_v2_final/models/topic_model.dart';
import 'package:focus_app_v2_final/models/user_model.dart';
import 'package:focus_app_v2_final/models/monthly_performance_model.dart';
import 'package:focus_app_v2_final/repositories/plan_repository.dart';
import 'package:focus_app_v2_final/repositories/user_repository.dart';
import 'package:focus_app_v2_final/services/auth_service.dart';
import 'package:focus_app_v2_final/services/authorization_service.dart';
import 'package:focus_app_v2_final/services/firestore_service.dart';

// --- TEMEL SERVİS PROVIDER'LARI ---
// Tüm servis ve repository nesneleri burada tek oluşturulur (singleton gibi davranır)

// Ham Firebase nesnelerini sağlar — diğer provider'lar bunları kullanır
final firebaseFirestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Kimlik doğrulama işlemleri (giriş, çıkış, kayıt) için servis
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(firebaseAuth: ref.watch(firebaseAuthProvider));
});
// Genel Firestore CRUD + chat + stats işlemleri için servis
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(firestore: ref.watch(firebaseFirestoreProvider));
});
// Özellik bazlı yetki kontrolü (premium vs free) — şimdilik hepsi true döner
final authorizationServiceProvider =
    Provider<AuthorizationService>((ref) => AuthorizationService());

// Kullanıcı CRUD işlemleri için repository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(firestore: ref.watch(firebaseFirestoreProvider));
});
// Plan, oturum, ders, konu CRUD işlemleri için repository
final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

// --- AUTHENTICATION (KİMLİK DOĞRULAMA) PROVIDERS ---

// Firebase Auth'tan gelen oturum değişikliklerini dinler (User? → null ise çıkış yapılmış)
final authStateChangesProvider = StreamProvider.autoDispose<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// currentUserProvider: Firebase Auth uid'sini alıp Firestore'dan tam UserModel'i çeker.
// Bu provider giriş/çıkış durumunu otomatik yönetir — uygulamada her yerden kullanılır.
final currentUserProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        return ref.read(userRepositoryProvider).getUserStream(user.uid);
      } else {
        return Stream.value(null);
      }
    },
    loading: () {
      return Stream.value(null);
    },
    error: (error, stackTrace) {
      return Stream.error('Authentication error: $error');
    },
  );
});

// --- DATA (VERİ) PROVIDERS ---

final examTypesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  return await ref.read(planRepositoryProvider).getExamTypes();
});

final studentsForCoachProvider =
    StreamProvider.autoDispose.family<List<UserModel>, String>((ref, coachId) {
  return ref.watch(userRepositoryProvider).getStudentsForCoach(coachId);
});

final assignedCoachProvider =
    StreamProvider.autoDispose.family<UserModel?, String>((ref, coachId) {
  return ref.watch(userRepositoryProvider).getUserStream(coachId);
});

final studySessionProvider = StreamProvider.autoDispose
    .family<StudySessionModel?, String>((ref, sessionId) {
  return ref
      .watch(planRepositoryProvider)
      .sessionsRef
      .doc(sessionId)
      .snapshots()
      .map((snapshot) {
    if (snapshot.exists && snapshot.data() != null) {
      return snapshot.data();
    }
    return null;
  });
});

final sessionByIdProvider =
    StreamProvider.family<StudySessionModel?, String>((ref, sessionId) {
  return ref.read(planRepositoryProvider).watchSessionById(sessionId);
});

// --- GLOBAL TOPIC PROVIDER ---

class TopicNotifier extends StateNotifier<List<TopicModel>> {
  final PlanRepository _repository;

  TopicNotifier(this._repository) : super([]);

  void setTopics(List<TopicModel> topics) {
    state = topics;
  }

  void updateRating(String studentId, String topicId, int rating) {
    // 1) Local Update (Arayüz anında güncellenir)
    state = [
      for (final topic in state)
        if (topic.id == topicId) topic.copyWith(rating: rating) else topic
    ];

    // 2) Backend Update (Firebase asenkron senkronizasyon)
    _repository.saveTopicRating(studentId, topicId, rating);
  }
}

final topicProvider =
    StateNotifierProvider<TopicNotifier, List<TopicModel>>((ref) {
  return TopicNotifier(ref.watch(planRepositoryProvider));
});

// Bugünün planlarını gerçek zamanlı dinler (Ana Sayfa sekmesi için kullanılır)
final todaysPlansProvider = StreamProvider.autoDispose
    .family<List<PlanModel>, String>((ref, studentId) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  return ref
      .watch(planRepositoryProvider)
      .getPlansForStudent(studentId, startOfDay, endOfDay);
});

// Belirli bir haftanın planlarını gerçek zamanlı dinler (Planlayıcı sekmesi için)
final weekPlansProvider = StreamProvider.autoDispose
    .family<List<PlanModel>, ({String studentId, DateTime weekDate})>(
        (ref, params) {
  final normalizedDate = DateTime(
      params.weekDate.year, params.weekDate.month, params.weekDate.day);
  final startOfWeek =
      normalizedDate.subtract(Duration(days: normalizedDate.weekday - 1));
  final endOfWeek = startOfWeek
      .add(const Duration(days: 7))
      .subtract(const Duration(milliseconds: 1));

  return ref
      .watch(planRepositoryProvider)
      .getPlansForStudent(params.studentId, startOfWeek, endOfWeek);
});

// Giriş yapmış öğrencinin sınav türüne göre dersleri getirir (örn: YKS dersleri)
final lessonsForUserProvider =
    FutureProvider.autoDispose<List<LessonModel>>((ref) {
  final userAsyncValue = ref.watch(currentUserProvider);

  return userAsyncValue.when(
    data: (userModel) {
      if (userModel == null ||
          userModel.examType == null ||
          userModel.examType!.isEmpty) {
        return [];
      }
      return ref
          .read(planRepositoryProvider)
          .getLessonsForExam(userModel.examType!);
    },
    error: (err, stack) {
      debugPrint('lessonsForUserProvider Hatası: $err');
      return [];
    },
    loading: () => [],
  );
});

// Tüm sınav türlerindeki tüm dersleri tek seferde çeker (yönetici/koç görünümü için)
final allLessonsProvider = FutureProvider<List<LessonModel>>((ref) async {
  final examTypes = await ref.read(planRepositoryProvider).getExamTypes();
  List<LessonModel> allLessons = [];
  for (final exam in examTypes) {
    final lessons =
        await ref.read(planRepositoryProvider).getLessonsForExam(exam);
    allLessons.addAll(lessons);
  }
  return allLessons;
});

// Belirli bir ders için konuları getirir (TaskEditor'da konu seçimi için)
final topicsForLessonProvider = FutureProvider.autoDispose
    .family<List<TopicModel>, ({String examId, String lessonId})>(
        (ref, params) {
  return ref
      .watch(planRepositoryProvider)
      .getTopicsForLesson(params.examId, params.lessonId);
});

// Öğrencinin ders bazlı birikimli istatistiklerini gerçek zamanlı dinler (İstatistikler sekmesi için)
final studentStatsProvider = StreamProvider.autoDispose
    .family<List<AggregatedStatsModel>, String>((ref, studentId) {
  return ref
      .watch(firestoreServiceProvider)
      .getAggregatedStatsForStudent(studentId);
});

// --- GLOBAL TOPIC PROVIDER ---

final monthlyPerformanceForLessonProvider = FutureProvider.family.autoDispose<
    List<MonthlyPerformance>, ({String studentId, String lessonId})>(
  (ref, params) {
    return ref.read(planRepositoryProvider).getMonthlyPerformanceForLesson(
          studentId: params.studentId,
          lessonId: params.lessonId,
        );
  },
);
