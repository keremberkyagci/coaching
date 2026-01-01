import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Bir öğrencinin belirli bir ders için toplanmış (aggregated) istatistiklerini temsil eder.
/// Bu model, Cloud Functions tarafından önceden hesaplanan verileri okumak için kullanılır,
/// bu da istemcinin yüzlerce plan dokümanı okumasını önleyerek maliyetleri düşürür.
class AggregatedStatsModel extends Equatable {
  final String lessonName;
  final int totalCorrect;
  final int totalIncorrect;
  final int totalEmpty;
  final int totalCount; // Toplam soru veya test sayısı gibi ek metrikler eklenebilir.

  const AggregatedStatsModel({
    required this.lessonName,
    this.totalCorrect = 0,
    this.totalIncorrect = 0,
    this.totalEmpty = 0,
    this.totalCount = 0,
  });

  /// Firestore'dan gelen veriden bir [AggregatedStatsModel] nesnesi oluşturur.
  factory AggregatedStatsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? {};
    return AggregatedStatsModel(
      lessonName: data['lessonName'] ?? 'Bilinmeyen Ders',
      totalCorrect: data['totalCorrect'] ?? 0,
      totalIncorrect: data['totalIncorrect'] ?? 0,
      totalEmpty: data['totalEmpty'] ?? 0,
      totalCount: data['totalCount'] ?? 0,
    );
  }

  /// Mevcut nesneyi Firestore'a yazılabilecek bir Map'e dönüştürür.
  /// Not: Bu modele genellikle istemci tarafından yazılmaz, Cloud Function tarafından yazılır.
  Map<String, dynamic> toFirestore() {
    return {
      'lessonName': lessonName,
      'totalCorrect': totalCorrect,
      'totalIncorrect': totalIncorrect,
      'totalEmpty': totalEmpty,
      'totalCount': totalCount,
    };
  }

  /// Mevcut nesnenin bir kopyasını oluştururken, belirtilen alanları günceller.
  AggregatedStatsModel copyWith({
    String? lessonName,
    int? totalCorrect,
    int? totalIncorrect,
    int? totalEmpty,
    int? totalCount,
  }) {
    return AggregatedStatsModel(
      lessonName: lessonName ?? this.lessonName,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      totalIncorrect: totalIncorrect ?? this.totalIncorrect,
      totalEmpty: totalEmpty ?? this.totalEmpty,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props => [lessonName, totalCorrect, totalIncorrect, totalEmpty, totalCount];
}