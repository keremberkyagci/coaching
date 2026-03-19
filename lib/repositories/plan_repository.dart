// ============================================================
// lib/repositories/plan_repository.dart — Planlama veri katmanı (ana repository)
//
// Uygulamanın en kapsamlı repository'si. 5 Firestore koleksiyonunu yönetir:
//   - plans          : Haftalık çalışma planları
//   - study_sessions : Tamamlanan çalışma oturumu verileri (D/Y/B sayıları)
//   - monthly_stats  : Aylık toplu istatistikler (grafik için)
//   - daily_stats    : Günlük toplu istatistikler (takvim görünümü için)
//   - users/{id}/aggregatedStats : Öğrenci başarı özeti (İstatistikler sekmesi)
//   - exam_types/{id}/lessons    : Ders listesi
//   - exam_types/{id}/lessons/{id}/topics : Konu listesi
//   - users/{id}/topic_ratings   : Öğrencinin konu yetkinlik dereceleri
//
// Kritik metod:
//   upsertStudySessionForPlan() — Bir görev tamamlandığında hem session kaydeder
//   hem plans, monthly_stats, daily_stats, aggregatedStats'i atomik günceller.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/lesson_model.dart';
import '../models/monthly_performance_model.dart';
import '../models/plan_model.dart';
import '../models/study_session_model.dart';
import '../models/topic_model.dart';

class PlanRepository {
  final FirebaseFirestore _db;

  PlanRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<PlanModel> get plansRef =>
      _db.collection('plans').withConverter<PlanModel>(
            fromFirestore: PlanModel.fromFirestore,
            toFirestore: (PlanModel model, _) => model.toFirestore(),
          );

  CollectionReference<StudySessionModel> get sessionsRef =>
      _db.collection('study_sessions').withConverter<StudySessionModel>(
            fromFirestore: (snapshot, _) => StudySessionModel.fromMap(
                snapshot.data()!,
                documentId: snapshot.id),
            toFirestore: (model, _) => model.toMap(),
          );

  CollectionReference<LessonModel> lessonsRef(String examId) => _db
      .collection('exam_types')
      .doc(examId)
      .collection('lessons')
      .withConverter<LessonModel>(
        fromFirestore: LessonModel.fromFirestore,
        toFirestore: (LessonModel model, _) => model.toFirestore(),
      );

  CollectionReference<TopicModel> topicsRef(String examId, String lessonId) =>
      _db
          .collection('exam_types')
          .doc(examId)
          .collection('lessons')
          .doc(lessonId)
          .collection('topics')
          .withConverter<TopicModel>(
            fromFirestore: TopicModel.fromFirestore,
            toFirestore: (TopicModel model, _) => model.toFirestore(),
          );

  Future<List<String>> getExamTypes() async {
    try {
      final snapshot = await _db.collection('exam_types').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint("Hata (getExamTypes): $e");
      return [];
    }
  }

  Future<List<LessonModel>> getLessonsForExam(String examId) async {
    try {
      final snapshot = await lessonsRef(examId).orderBy('order').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Hata (getLessonsForExam): $e");
      return [];
    }
  }

  Future<List<TopicModel>> getTopicsForLesson(
      String examId, String lessonId) async {
    try {
      final snapshot = await topicsRef(examId, lessonId).orderBy('order').get();
      return snapshot.docs
          .map((doc) => doc.data().copyWith(lessonId: lessonId))
          .toList();
    } catch (e) {
      debugPrint("Hata (getTopicsForLesson): $e");
      return [];
    }
  }

  /// App açıldığında öğrenciye ait tüm derslerin tüm konularını tek seferde çeker.
  /// İlgili konular için öğrencinin verdiği "rating" verisini de `topic_ratings` alt koleksiyonundan eşler.
  Future<List<TopicModel>> getAllTopicsForStudent(String studentId) async {
    try {
      final examTypes = await getExamTypes();
      List<TopicModel> allTopics = [];

      for (final exam in examTypes) {
        final lessons = await getLessonsForExam(exam);
        for (final lesson in lessons) {
          if (lesson.id == null) continue;
          final topics = await getTopicsForLesson(exam, lesson.id!);
          allTopics.addAll(topics);
        }
      }

      // Öğrencinin `topic_ratings` koleksiyonunu da 1 kere çekip eşleştiriyoruz
      final ratingsSnapshot = await _db
          .collection('users')
          .doc(studentId)
          .collection('topic_ratings')
          .get();

      final Map<String, int> ratingMap = {};
      for (final doc in ratingsSnapshot.docs) {
        ratingMap[doc.id] = (doc.data()['rating'] ?? 0) as int;
      }

      // Eşleştirme
      return allTopics.map((topic) {
        if (topic.id != null && ratingMap.containsKey(topic.id)) {
          return topic.copyWith(rating: ratingMap[topic.id]);
        }
        return topic;
      }).toList();
    } catch (e) {
      debugPrint("Hata (getAllTopicsForStudent): $e");
      return [];
    }
  }

  /// Öğrencinin spesifik bir konuya olan yetkinlik derecesini asenkron olarak kaydeder.
  Future<void> saveTopicRating(
      String studentId, String topicId, int rating) async {
    try {
      await _db
          .collection('users')
          .doc(studentId)
          .collection('topic_ratings')
          .doc(topicId)
          .set({
        'rating': rating,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Hata (saveTopicRating): $e");
    }
  }

  Stream<List<PlanModel>> getPlansForStudent(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return plansRef
        .where('studentId', isEqualTo: studentId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> addPlan(PlanModel plan) async {
    if (plan.id != null) {
      await plansRef.doc(plan.id).set(plan, SetOptions(merge: true));
    } else {
      await plansRef.add(plan);
    }
  }

  Future<void> updatePlanStatus(String planId, bool isCompleted) async {
    await plansRef.doc(planId).update({'isCompleted': isCompleted});
  }

  Future<void> detachSessionFromPlan(String planId) async {
    await plansRef.doc(planId).update({
      'isCompleted': false,
      'sessionId': null,
    });
  }

  Stream<StudySessionModel?> watchSessionById(String sessionId) {
    return sessionsRef.doc(sessionId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data();
    });
  }

  Future<StudySessionModel?> getSessionById(String sessionId) async {
    final doc = await sessionsRef.doc(sessionId).get();
    return doc.data();
  }

  /// Yeni bir çalışma oturumu oluşturur, planı günceller ve aylık özet istatistiklerini artırır.
  Future<String> upsertStudySessionForPlan({
    required PlanModel plan,
    required int correct,
    required int wrong,
    required int blank,
  }) async {
    final now = DateTime.now();
    final session = StudySessionModel(
      uid: plan.sessionId,
      studentId: plan.studentId,
      planId: plan.id,
      lessonId: plan.lessonId,
      subject: plan.lessonName,
      topic: plan.topicName,
      durationMinutes: 0,
      sessionDate: Timestamp.fromDate(now),
      sessionType: plan.activityType,
      correct: correct,
      wrong: wrong,
      blank: blank,
    );

    String sessionId;
    if (plan.sessionId != null && plan.sessionId!.isNotEmpty) {
      sessionId = plan.sessionId!;
      await sessionsRef.doc(sessionId).set(session, SetOptions(merge: true));
      await plansRef.doc(plan.id).update({
        'isCompleted': true,
      });
    } else {
      final docRef = await sessionsRef.add(session);
      sessionId = docRef.id;
      await plansRef.doc(plan.id).update({
        'isCompleted': true,
        'sessionId': sessionId,
      });
    }

    // Aylık özet istatistiklerini atomik olarak güncelle
    final monthId = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    final monthlyStatRef = _db
        .collection('monthly_stats')
        .doc("${plan.studentId}_${plan.lessonId}_$monthId");

    await monthlyStatRef.set({
      'studentId': plan.studentId,
      'lessonId': plan.lessonId,
      'lessonName': plan.lessonName,
      'year': now.year,
      'month': now.month,
      'totalCorrect': FieldValue.increment(correct),
      'totalWrong': FieldValue.increment(wrong),
      'totalBlank': FieldValue.increment(blank),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // YENİ: Günlük özet istatistiklerini atomik olarak güncelle (Firebase Okuma Optimizasyonu)
    final dayId =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final dailyStatRef = _db.collection('daily_stats').doc(
        "${plan.studentId}_${plan.lessonName}_${plan.activityType.name}_$dayId");

    await dailyStatRef.set({
      'studentId': plan.studentId,
      'lessonName': plan.lessonName,
      'sessionType': plan.activityType.name,
      'year': now.year,
      'month': now.month,
      'day': now.day,
      'totalCorrect': FieldValue.increment(correct),
      'totalWrong': FieldValue.increment(wrong),
      'totalBlank': FieldValue.increment(blank),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // YENİ: Öğrencinin genel "aggregatedStats" istatistiğini atomik olarak güncelle
    final aggregatedStatRef = _db
        .collection('users')
        .doc(plan.studentId)
        .collection('aggregatedStats')
        .doc(plan.lessonId);

    await aggregatedStatRef.set({
      'lessonId': plan.lessonId,
      'lessonName': plan.lessonName,
      'totalCorrect': FieldValue.increment(correct),
      'totalIncorrect': FieldValue.increment(wrong),
      'totalEmpty': FieldValue.increment(blank),
      'totalCount': FieldValue.increment(correct + wrong + blank),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return sessionId;
  }

  /// Belirli bir öğrenci, ders ve aktivite tipi için günlük istatistikleri getirir.
  Stream<Map<DateTime, Map<String, num>>> getDailyStatsForLesson(
    String studentId,
    String lessonName,
    ActivityType activityType,
  ) {
    return _db
        .collection('daily_stats')
        .where('studentId', isEqualTo: studentId)
        .where('lessonName', isEqualTo: lessonName)
        .where('sessionType', isEqualTo: activityType.name)
        .snapshots()
        .map((snapshot) {
      final Map<DateTime, Map<String, num>> dailyStats = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Counter dökümanındaki değerleri Date formatına getiriyoruz.
        final int year = data['year'] ?? 0;
        final int month = data['month'] ?? 0;
        final int dayNum = data['day'] ?? 0;

        if (year == 0 || month == 0 || dayNum == 0) continue;

        final day = DateTime(year, month, dayNum);

        final num correct = data['totalCorrect'] ?? 0;
        final num incorrect = data['totalWrong'] ?? 0;
        final num empty = data['totalBlank'] ?? 0;

        dailyStats[day] = {
          'correct': correct,
          'incorrect': incorrect,
          'empty': empty,
        };

        final total = correct + incorrect + empty;
        dailyStats[day]!['successRate'] =
            total == 0 ? 0.0 : (correct / total) * 100;
      }

      return dailyStats;
    });
  }

  /// Belirli bir öğrenci ve ders için agrege edilmiş aylık istatistikleri getirir.
  Future<Map<String, int>> getMonthlyStats({
    required String studentId,
    required String lessonId,
    required int year,
    required int month,
  }) async {
    try {
      final monthId = "$year-${month.toString().padLeft(2, '0')}";
      final doc = await _db
          .collection('monthly_stats')
          .doc("${studentId}_${lessonId}_$monthId")
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'totalCorrect': data['totalCorrect'] ?? 0,
          'totalWrong': data['totalWrong'] ?? 0,
          'totalBlank': data['totalBlank'] ?? 0,
        };
      }
      return {'totalCorrect': 0, 'totalWrong': 0, 'totalBlank': 0};
    } catch (e) {
      debugPrint("Hata (getMonthlyStats): $e");
      return {'totalCorrect': 0, 'totalWrong': 0, 'totalBlank': 0};
    }
  }

  Future<List<MonthlyPerformance>> getMonthlyPerformanceForLesson({
    required String studentId,
    required String lessonId,
    int monthCount = 6,
  }) async {
    final now = DateTime.now();
    List<MonthlyPerformance> result = [];

    for (int i = monthCount - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final stats = await getMonthlyStats(
        studentId: studentId,
        lessonId: lessonId,
        year: date.year,
        month: date.month,
      );

      result.add(
        MonthlyPerformance.fromStats(
          month: DateFormat('MMM', 'tr_TR').format(date),
          totalCorrect: stats['totalCorrect'] ?? 0,
          totalWrong: stats['totalWrong'] ?? 0,
          totalBlank: stats['totalBlank'] ?? 0,
        ),
      );
    }

    return result;
  }
}
