// lib/models/monthly_performance_model.dart

import 'package:equatable/equatable.dart';

/// Grafiklerde aylık performans oranlarını göstermek için kullanılan veri modeli.
class MonthlyPerformance extends Equatable {
  /// Ay ismi (Örn: "Ocak", "Şubat") veya tarih etiketi
  final String month;

  /// Doğru cevapların oranı (0.0 - 1.0 arası)
  final double correctRatio;

  /// Yanlış cevapların oranı (0.0 - 1.0 arası)
  final double wrongRatio;

  /// Boş bırakılanların oranı (0.0 - 1.0 arası)
  final double blankRatio;

  const MonthlyPerformance({
    required this.month,
    required this.correctRatio,
    required this.wrongRatio,
    required this.blankRatio,
  });

  /// Ham istatistik verilerinden MonthlyPerformance nesnesi üretir.
  factory MonthlyPerformance.fromStats({
    required String month,
    required int totalCorrect,
    required int totalWrong,
    required int totalBlank,
  }) {
    final int total = totalCorrect + totalWrong + totalBlank;

    if (total == 0) {
      return MonthlyPerformance(
        month: month,
        correctRatio: 0.0,
        wrongRatio: 0.0,
        blankRatio: 0.0,
      );
    }

    return MonthlyPerformance(
      month: month,
      correctRatio: totalCorrect / total,
      wrongRatio: totalWrong / total,
      blankRatio: totalBlank / total,
    );
  }

  /// Yüzdelik değerleri string olarak döndüren yardımcı getter'lar (Örn: %75)
  String get correctPercentage => '${(correctRatio * 100).toStringAsFixed(1)}%';
  String get wrongPercentage => '${(wrongRatio * 100).toStringAsFixed(1)}%';
  String get blankPercentage => '${(blankRatio * 100).toStringAsFixed(1)}%';

  @override
  List<Object?> get props => [month, correctRatio, wrongRatio, blankRatio];
}
