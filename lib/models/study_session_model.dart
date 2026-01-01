// lib/models/study_session_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// StudySessionModel: Öğrencinin yaptığı her bir ders çalışma oturumunun kaydını tutar.
class StudySessionModel {
  final String? uid; // Oturumun benzersiz kimliği (Firestore tarafından verilir)
  final String studentId; // Hangi öğrencinin oturumu olduğu
  final String subject; // Çalışılan ders (Örn: Matematik, Fizik)
  final String topic; // Çalışılan konu (Örn: Türev, Olasılık)
  final int durationMinutes; // Çalışma süresi (Dakika cinsinden)
  final Timestamp sessionDate; // Oturumun gerçekleştiği tarih ve saat
  final Timestamp? createdAt; // Oturumun oluşturulduğu tarih

  StudySessionModel({
    this.uid,
    required this.studentId,
    required this.subject,
    required this.topic,
    required this.durationMinutes,
    required this.sessionDate,
    this.createdAt,
  });

  // Firestore'dan veri okumak için
  factory StudySessionModel.fromMap(Map<String, dynamic> data) {
    return StudySessionModel(
      uid: data['uid'],
      studentId: data['studentId'] ?? '',
      subject: data['subject'] ?? '',
      topic: data['topic'] ?? '',
      durationMinutes: (data['durationMinutes'] ?? 0),
      sessionDate: data['sessionDate'] ?? Timestamp.now(),
      createdAt: data['createdAt'],
    );
  }

  // Firestore'a veri yazmak için
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'subject': subject,
      'topic': topic,
      'durationMinutes': durationMinutes,
      'sessionDate': sessionDate,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  // Modeli kopyalayıp belirli alanları güncellemek için
  StudySessionModel copyWith({
    String? uid,
    String? studentId,
    String? subject,
    String? topic,
    int? durationMinutes,
    Timestamp? sessionDate,
    Timestamp? createdAt,
  }) {
    return StudySessionModel(
      uid: uid ?? this.uid,
      studentId: studentId ?? this.studentId,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sessionDate: sessionDate ?? this.sessionDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
