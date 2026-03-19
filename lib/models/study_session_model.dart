import 'package:cloud_firestore/cloud_firestore.dart';
import 'plan_model.dart';

class StudySessionModel {
  final String? uid;
  final String studentId;

  // YENİ
  final String? planId;
  final String? lessonId;

  final String subject;
  final String topic;
  final int durationMinutes;
  final Timestamp sessionDate;
  final Timestamp? createdAt;
  final ActivityType sessionType;

  final int? correct;
  final int? wrong;
  final int? blank;

  StudySessionModel({
    this.uid,
    required this.studentId,
    this.planId,
    this.lessonId,
    required this.subject,
    required this.topic,
    required this.durationMinutes,
    required this.sessionDate,
    required this.sessionType,
    this.createdAt,
    this.correct,
    this.wrong,
    this.blank,
  });

  factory StudySessionModel.fromMap(
      Map<String, dynamic> data, {
        String? documentId,
      }) {
    return StudySessionModel(
      uid: documentId ?? data['uid'],
      studentId: data['studentId'] ?? '',
      planId: data['planId'],
      lessonId: data['lessonId'],
      subject: data['subject'] ?? '',
      topic: data['topic'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 0,
      sessionDate: data['sessionDate'] ?? Timestamp.now(),
      sessionType: _parseSessionType(data['sessionType']),
      createdAt: data['createdAt'],
      correct: data['correct'],
      wrong: data['wrong'],
      blank: data['blank'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'planId': planId,
      'lessonId': lessonId,
      'subject': subject,
      'topic': topic,
      'durationMinutes': durationMinutes,
      'sessionDate': sessionDate,
      'sessionType': sessionType.name,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'correct': correct,
      'wrong': wrong,
      'blank': blank,
    };
  }

  static ActivityType _parseSessionType(String? type) {
    return ActivityType.values.firstWhere(
          (e) => e.name == type,
      orElse: () => ActivityType.study,
    );
  }

  StudySessionModel copyWith({
    String? uid,
    String? studentId,
    String? planId,
    String? lessonId,
    String? subject,
    String? topic,
    int? durationMinutes,
    Timestamp? sessionDate,
    ActivityType? sessionType,
    Timestamp? createdAt,
    int? correct,
    int? wrong,
    int? blank,
  }) {
    return StudySessionModel(
      uid: uid ?? this.uid,
      studentId: studentId ?? this.studentId,
      planId: planId ?? this.planId,
      lessonId: lessonId ?? this.lessonId,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sessionDate: sessionDate ?? this.sessionDate,
      sessionType: sessionType ?? this.sessionType,
      createdAt: createdAt ?? this.createdAt,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      blank: blank ?? this.blank,
    );
  }
}