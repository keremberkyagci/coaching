import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/lesson_model.dart';
import '../models/plan_model.dart';
import '../models/topic_model.dart';

class PlanRepository {
  final FirebaseFirestore _db;

  PlanRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<PlanModel> get plansRef =>
      _db.collection('plans').withConverter<PlanModel>(
            fromFirestore: PlanModel.fromFirestore,
            toFirestore: (PlanModel model, options) => model.toFirestore(),
          );

  CollectionReference<LessonModel> lessonsRef(String examId) =>
      _db.collection('exam_types').doc(examId).collection('lessons').withConverter<LessonModel>(
            fromFirestore: LessonModel.fromFirestore,
            toFirestore: (LessonModel model, options) => model.toFirestore(),
          );

  CollectionReference<TopicModel> topicsRef(String examId, String lessonId) =>
      _db.collection('exam_types').doc(examId).collection('lessons').doc(lessonId).collection('topics').withConverter<TopicModel>(
            fromFirestore: TopicModel.fromFirestore,
            toFirestore: (TopicModel model, options) => model.toFirestore(),
          );

  Future<List<LessonModel>> getLessonsForExam(String examId) async {
    try {
      final snapshot = await lessonsRef(examId).orderBy('order').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Hata (getLessonsForExam): $e");
      return [];
    }
  }

  Future<List<TopicModel>> getTopicsForLesson(String examId, String lessonId) async {
    try {
      final snapshot = await topicsRef(examId, lessonId).orderBy('order').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Hata (getTopicsForLesson): $e");
      return [];
    }
  }

  Stream<List<PlanModel>> getPlansForStudent(String studentId, DateTime startDate, DateTime endDate) {
    return plansRef
        .where('studentId', isEqualTo: studentId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
  
  Future<void> addPlan(PlanModel plan) async {
    // Eğer planın bir id'si varsa güncelle, yoksa yeni ekle.
    if (plan.id != null) {
      await plansRef.doc(plan.id).set(plan, SetOptions(merge: true));
    } else {
      await plansRef.add(plan);
    }
  }

  Future<void> updatePlanStatus(String planId, bool isCompleted) async {
    await plansRef.doc(planId).update({'isCompleted': isCompleted});
  }

  Future<void> updatePlanStats(String planId, int correctCount,
      int incorrectCount, int emptyCount) async {
    await plansRef.doc(planId).update({
      'details.correctCount': correctCount,
      'details.incorrectCount': incorrectCount,
      'details.emptyCount': emptyCount,
      'isCompleted': true, // Sonuç girildiğinde otomatik tamamlandı yap
    });
  }

  Stream<Map<DateTime, Map<String, num>>> getDailyStatsForLesson(
      String studentId, String lessonName, ActivityType activityType) {
    // ... (mevcut kod)
        return Stream.value({});
  }
}
