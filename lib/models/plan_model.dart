import 'package:cloud_firestore/cloud_firestore.dart';

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

  // YENİ
  final String? sessionId;

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
    this.sessionId,
  });

  factory PlanModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data() ?? {};

    final createdAtData = data['createdAt'];
    final createdAt =
    createdAtData is Timestamp ? createdAtData : Timestamp.now();

    return PlanModel(
      id: snapshot.id,
      studentId: data['studentId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lessonName: data['lessonName'] ?? '',
      lessonType: data['lessonType'],
      isCompleted: data['isCompleted'] ?? false,
      createdBy: data['createdBy'] ?? '',
      createdAt: createdAt,
      details: PlanDetails.fromMap(data['details'] ?? {}),
      activityType: ActivityType.values.firstWhere(
            (e) => e.name == data['activityType'],
        orElse: () => ActivityType.test,
      ),
      lessonId: data['lessonId'] ?? '',
      topicName: data['topicName'] ?? '',
      sessionId: data['sessionId'],
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
      'sessionId': sessionId,
    };
  }

  PlanModel copyWith({
    String? id,
    String? studentId,
    DateTime? date,
    String? lessonName,
    String? lessonType,
    bool? isCompleted,
    String? createdBy,
    Timestamp? createdAt,
    PlanDetails? details,
    ActivityType? activityType,
    String? lessonId,
    String? topicName,
    String? sessionId,
  }) {
    return PlanModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      lessonName: lessonName ?? this.lessonName,
      lessonType: lessonType ?? this.lessonType,
      isCompleted: isCompleted ?? this.isCompleted,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      details: details ?? this.details,
      activityType: activityType ?? this.activityType,
      lessonId: lessonId ?? this.lessonId,
      topicName: topicName ?? this.topicName,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

enum ActivityType { test, study, branchTrial, breakTime, other }

abstract class PlanDetails {
  Map<String, dynamic> toMap();

  factory PlanDetails.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('plannedQuestionCount')) {
      return TestDetails.fromMap(map);
    } else if (map.containsKey('durationMinutes')) {
      return StudyDetails.fromMap(map);
    } else {
      return StudyDetails(durationMinutes: 0);
    }
  }
}

// Artık sadece hedefi tutuyor
class TestDetails implements PlanDetails {
  final int? plannedQuestionCount;

  TestDetails({this.plannedQuestionCount});

  factory TestDetails.fromMap(Map<String, dynamic> map) {
    return TestDetails(
      plannedQuestionCount: map['plannedQuestionCount'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'plannedQuestionCount': plannedQuestionCount,
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