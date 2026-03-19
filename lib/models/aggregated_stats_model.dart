import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Bir öğrencinin belirli bir ders için toplanmış (aggregated) istatistiklerini temsil eder.
class AggregatedStatsModel extends Equatable {
  final String? lessonId; // EKLENDİ
  final String lessonName;
  final int totalCorrect;
  final int totalIncorrect;
  final int totalEmpty;
  final int totalCount; 

  const AggregatedStatsModel({
    this.lessonId, // EKLENDİ
    required this.lessonName,
    this.totalCorrect = 0,
    this.totalIncorrect = 0,
    this.totalEmpty = 0,
    this.totalCount = 0,
  });

  factory AggregatedStatsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? {};
    return AggregatedStatsModel(
      lessonId: data['lessonId'] ?? snapshot.id, // lessonId yoksa döküman ID'sini (genelde lessonId olur) al
      lessonName: data['lessonName'] ?? 'Bilinmeyen Ders',
      totalCorrect: data['totalCorrect'] ?? 0,
      totalIncorrect: data['totalIncorrect'] ?? 0,
      totalEmpty: data['totalEmpty'] ?? 0,
      totalCount: data['totalCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (lessonId != null) 'lessonId': lessonId,
      'lessonName': lessonName,
      'totalCorrect': totalCorrect,
      'totalIncorrect': totalIncorrect,
      'totalEmpty': totalEmpty,
      'totalCount': totalCount,
    };
  }

  AggregatedStatsModel copyWith({
    String? lessonId,
    String? lessonName,
    int? totalCorrect,
    int? totalIncorrect,
    int? totalEmpty,
    int? totalCount,
  }) {
    return AggregatedStatsModel(
      lessonId: lessonId ?? this.lessonId,
      lessonName: lessonName ?? this.lessonName,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalIncorrect: totalIncorrect ?? this.totalIncorrect,
      totalEmpty: totalEmpty ?? this.totalEmpty,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props => [lessonId, lessonName, totalCorrect, totalIncorrect, totalEmpty, totalCount];
}
