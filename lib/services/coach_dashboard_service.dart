// lib/services/coach_dashboard_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/plan_model.dart';

// Öğrenci ilerlemesini ve modelini bir arada tutan bir yardımcı sınıf
class StudentProgress {
  final UserModel student;
  final int totalTasks;
  final int completedTasks;
  final List<PlanModel> todaysTasks;

  StudentProgress({
    required this.student,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.todaysTasks = const [],
  });

  double get progress => totalTasks > 0 ? completedTasks / totalTasks : 0.0;
}

// Koç paneli için tüm verileri tek bir yerde toplayan model.
class CoachDashboardData {
  final int totalStudents;
  final int totalTasksToday;
  final int completedTasksToday;
  final List<StudentProgress> studentProgressList;

  CoachDashboardData({
    this.totalStudents = 0,
    this.totalTasksToday = 0,
    this.completedTasksToday = 0,
    this.studentProgressList = const [],
  });

  double get overallCompletionRate =>
      totalTasksToday > 0 ? completedTasksToday / totalTasksToday : 0.0;
}

class CoachDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _coachId = FirebaseAuth.instance.currentUser?.uid;

  // Gerekli tüm dashboard verilerini tek bir seferde çeken ana stream fonksiyonu
  Stream<CoachDashboardData> getDashboardDataStream() {
    if (_coachId == null) {
      return Stream.value(CoachDashboardData());
    }

    // Önce koçun onaylanmış tüm öğrencilerinin stream'ini al
    return _firestore
        .collection('users')
        .where('userType', isEqualTo: 'student')
        .where('coachConnection.coachId', isEqualTo: _coachId)
        .where('coachConnection.status', isEqualTo: 'approved')
        .snapshots()
        .asyncMap((studentSnapshot) async {
      final students = studentSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();

      if (students.isEmpty) {
        return CoachDashboardData();
      }

      final studentIds = students.map((s) => s.id).toList();
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Tüm öğrencilerin bugünkü planlarını tek bir sorguda al
      final planSnapshot = await _firestore
          .collection('plans')
          .where('studentId', whereIn: studentIds)
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThan: endOfDay)
          .get();

      final allTodaysPlans = planSnapshot.docs
          .map((doc) => PlanModel.fromFirestore(doc, null))
          .toList();

      // Her bir öğrenci için ilerlemeyi hesapla
      final studentProgressList = students.map((student) {
        final studentPlans = allTodaysPlans
            .where((plan) => plan.studentId == student.id)
            .toList();
        return StudentProgress(
          student: student,
          totalTasks: studentPlans.length,
          completedTasks:
              studentPlans.where((p) => p.isCompleted == true).length,
          todaysTasks: studentPlans, // Öğrencinin güncel görevlerini ekle
        );
      }).toList();

      // Genel istatistikleri hesapla
      return CoachDashboardData(
        totalStudents: students.length,
        totalTasksToday: allTodaysPlans.length,
        completedTasksToday:
            allTodaysPlans.where((p) => p.isCompleted == true).length,
        studentProgressList: studentProgressList,
      );
    });
  }
}
