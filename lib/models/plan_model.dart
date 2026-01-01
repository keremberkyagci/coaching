import 'package:cloud_firestore/cloud_firestore.dart';

// Ana Plan Modeli
class PlanModel {
  final String? id;
  final String studentId;
  final DateTime date;
  final String lessonName;
  final String? lessonType; 
  final bool isCompleted;
  final String createdBy;
  final Timestamp createdAt;
  final PlanDetails details;
  
  final ActivityType activityType;
  final String lessonId;
  final String topicName;

  PlanModel({
    this.id,
    required this.studentId,
    required this.date,
    required this.lessonName,
    this.lessonType,
    this.isCompleted = false,
    required this.createdBy,
    required this.createdAt,
    required this.details,
    required this.activityType,
    required this.lessonId,
    required this.topicName,
  });

  factory PlanModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    
    final createdAtData = data['createdAt'];
    final createdAt = createdAtData is Timestamp ? createdAtData : Timestamp.now();

    return PlanModel(
      id: snapshot.id,
      studentId: data['studentId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      lessonName: data['lessonName'] ?? '',
      lessonType: data['lessonType'],
      isCompleted: data['isCompleted'] ?? false,
      createdBy: data['createdBy'] ?? '',
      createdAt: createdAt,
      details: PlanDetails.fromMap(data['details'] ?? {}),
      activityType: ActivityType.values.firstWhere((e) => e.name == data['activityType'], orElse: () => ActivityType.test),
      lessonId: data['lessonId'] ?? '',
      topicName: data['topicName'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'date': Timestamp.fromDate(date),
      'lessonName': lessonName,
      'lessonType': lessonType,
      'isCompleted': isCompleted,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'details': details.toMap(),
      'activityType': activityType.name,
      'lessonId': lessonId,
      'topicName': topicName,
    };
  }
}

enum ActivityType { test, study, branchTrial, breakTime, other }

abstract class PlanDetails {
  Map<String, dynamic> toMap();
  
  factory PlanDetails.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('plannedQuestionCount') || map.containsKey('correctCount')) {
      return TestDetails.fromMap(map);
    } else if (map.containsKey('durationMinutes')) {
      return StudyDetails.fromMap(map);
    } else {
      return StudyDetails(durationMinutes: 0);
    }
  }
}

// DÜZENLENDİ: Hem planlanan soru adedini hem de sonuçları tutabilir.
class TestDetails implements PlanDetails {
  final int? plannedQuestionCount;
  final int? correctCount;
  final int? incorrectCount;
  final int? emptyCount;

  // Girilen sonuçlara göre toplam soru sayısını hesaplar.
  int get actualQuestionCount => (correctCount ?? 0) + (incorrectCount ?? 0) + (emptyCount ?? 0);

  TestDetails({this.plannedQuestionCount, this.correctCount, this.incorrectCount, this.emptyCount});
  
  factory TestDetails.fromMap(Map<String, dynamic> map) {
    return TestDetails(
      plannedQuestionCount: map['plannedQuestionCount'],
      correctCount: map['correctCount'],
      incorrectCount: map['incorrectCount'],
      emptyCount: map['emptyCount'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'plannedQuestionCount': plannedQuestionCount,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'emptyCount': emptyCount,
    };
  }
}

class StudyDetails implements PlanDetails {
  final int durationMinutes;

  StudyDetails({required this.durationMinutes});
  
  factory StudyDetails.fromMap(Map<String, dynamic> map) {
    return StudyDetails(
      durationMinutes: map['durationMinutes'] ?? 0,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'durationMinutes': durationMinutes,
    };
  }
}
