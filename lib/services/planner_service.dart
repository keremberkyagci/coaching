import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plan_model.dart';

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
      // Not: Yeni ID'nin atanması için plan nesnesini kaynayan fonksiyondan yeniden çekmeliyiz
      await _firestore.collection('plans').add(plan.toFirestore());
    }
  }

  Future<void> deletePlan(String planId) async {
    await _firestore.collection('plans').doc(planId).delete();
  }
}
