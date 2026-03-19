// ============================================================
// lib/services/performance_service.dart — Performans verisi işleme servisi
//
// Son 6 ayın performans verisini hesaplar ve grafiklere hazır hale getirir:
//   - getMonthlyStats()             : Son 6 aya ait doğru/yanlış/boş verilerini döndürür
//   - generatePerformanceComment()  : Son 2 aya göre artış/düşüş yorumu üretir
//   - _getMonthName()               : Ay numarasını kısa Türkçe isme çevirir (1→'Oca' gibi)
//
// Veriyi PlanRepository.getMonthlyStats() üzerinden 'monthly_stats' koleksiyonundan çeker.
// ============================================================

import '../models/monthly_performance_model.dart';
import '../repositories/plan_repository.dart';

/// Öğrenci performans verilerini işleyen ve grafiklere hazır hale getiren servis.
class PerformanceService {
  final PlanRepository _planRepository;

  PerformanceService(this._planRepository);

  /// Belirli bir öğrenci ve ders için son 6 ayın performans verilerini getirir.
  /// Verileri 'monthly_stats' koleksiyonundan (agrege edilmiş tablo) çeker.
  Future<List<MonthlyPerformance>> getMonthlyStats(
    String studentId,
    String lessonId,
  ) async {
    final now = DateTime.now();
    List<MonthlyPerformance> performanceList = [];

    // Son 6 ayın verisini (en eskiden yeniye) çekelim
    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);

      final stats = await _planRepository.getMonthlyStats(
        studentId: studentId,
        lessonId: lessonId,
        year: targetDate.year,
        month: targetDate.month,
      );

      performanceList.add(MonthlyPerformance.fromStats(
        month: _getMonthName(targetDate.month),
        totalCorrect: stats['totalCorrect'] ?? 0,
        totalWrong: stats['totalWrong'] ?? 0,
        totalBlank: stats['totalBlank'] ?? 0,
      ));
    }

    return performanceList;
  }

  /// Performans verilerine göre yorum oluşturur.
  String generatePerformanceComment(List<MonthlyPerformance> data) {
    if (data.length < 2) return "Yeterli veri yok";

    final last = data.last;
    final prev = data[data.length - 2];

    if (last.correctRatio > prev.correctRatio) {
      return "📈 Performansın artıyor, böyle devam et!";
    } else if (last.correctRatio < prev.correctRatio) {
      return "⚠ Son ayda düşüş var, tekrar yapmalısın.";
    } else {
      return "📊 Performans stabil.";
    }
  }

  String _getMonthName(int month) {
    const names = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];
    return names[month - 1];
  }
}
