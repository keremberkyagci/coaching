// ============================================================
// lib/services/planner_service.dart — Planlama CRUD servisi (eski katman)
//
// PlanRepository'nin önceki versiyonu olarak düşünülebilir.
// Aynı işleri yapan iki katman var; aktif kodda PlanRepository kullanılmaktadır.
//
// Metodlar:
//   - getPlansForDay()         : Belirli güne ait planları getirir
//   - saveOrUpdatePlan()       : Plan varsa güncelle, yoksa oluştur (ID kontrolü ile)
//   - deletePlan()             : Plan sil
//   - createStudySession()     : Yeni çalışma seansı oluştur, ID döndür
//   - attachSessionToPlan()    : Seansı plana bağla ve planı tamamlandı işaretle
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plan_model.dart';
import '../models/study_session_model.dart';

class PlannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<PlanModel>> getPlansForDay(
      String studentId, DateTime targetDay) async {
    final startOfDay = DateTime(targetDay.year, targetDay.month, targetDay.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final snapshot = await _firestore
        .collection('plans')
        .where('studentId', isEqualTo: studentId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .orderBy('createdAt')
        .get();
    return snapshot.docs
        .map((doc) => PlanModel.fromFirestore(doc, null))
        .toList();
  }

  Future<void> saveOrUpdatePlan(PlanModel plan) async {
    if (plan.id != null && plan.id!.isNotEmpty) {
      // Planın bir ID'si var, mevcut belgeyi güncelle
      await _firestore
          .collection('plans')
          .doc(plan.id)
          .update(plan.toFirestore());
    } else {
      // Planın bir ID'si yok, yeni bir belge olarak ekle
      await _firestore.collection('plans').add(plan.toFirestore());
    }
  }

  Future<void> deletePlan(String planId) async {
    await _firestore.collection('plans').doc(planId).delete();
  }

  /// Yeni bir çalışma oturumu oluşturur ve atanan ID'yi döndürür.
  Future<String> createStudySession(StudySessionModel session) async {
    final docRef = await _firestore.collection('study_sessions').add(session.toMap());
    return docRef.id;
  }

  /// Bir çalışma oturumunu ilgili plana bağlar ve planı tamamlandı olarak işaretler.
  Future<void> attachSessionToPlan(String planId, String sessionId) async {
    await _firestore.collection('plans').doc(planId).update({
      'sessionId': sessionId,
      'isCompleted': true,
    });
  }
}
