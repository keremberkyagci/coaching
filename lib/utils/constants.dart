// ============================================================
// lib/utils/constants.dart — Uygulama genelinde kullanılan sabitler
//
// Birden fazla dosyada kullanılan listeler ve yardımcı fonksiyon burada tutuludur:
//   - daysOfWeek           : Türkçe kısa gün isimleri (Planlayıcı takvimi için)
//   - yksSubjects          : YKS ders listesi (StudySessionInputScreen dropdown)
//   - activityTypes        : Görev türleri (UI'da gösterim için)
//   - adherenceStatusOptions: Plan uyum durumu etiketleri (tamamlandı, devam ediyor vb.)
//   - calculatePerformanceRatios(): D/Y/B sayılarından yüzde oranı hesaplar
//                                   Toplam 0 ise tüm değerler 0.0 döner (sıfıra bölme hatası engellenir)
// ============================================================

const List<String> daysOfWeek = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

const List<String> yksSubjects = [
  'Türkçe', 'Matematik', 'Fizik', 'Kimya', 'Biyoloji',
  'Din Kültürü', 'Coğrafya', 'Tarih', 'Felsefe'
];

const List<String> activityTypes = [
  'Konu Çalışması', 'Test', 'Branş Denemesi'
];

const Map<String, String> adherenceStatusOptions = {
  'complied': 'Tamamlandı',
  'in_progress': 'Devam Ediyor',
  'not_complied': 'Yapılmadı',
  'skipped': 'Geçildi',
};

/// Aylık performans verilerinden yüzde oranlarını hesaplar.
/// Toplam 0 ise tüm oranları 0.0 döndürür.
/// Sonuçların toplamı her zaman 1.0 (yani %100) olur.
Map<String, double> calculatePerformanceRatios({
  required int correct,
  required int wrong,
  required int blank,
}) {
  final int total = correct + wrong + blank;

  if (total == 0) {
    return {
      'correctRatio': 0.0,
      'wrongRatio': 0.0,
      'blankRatio': 0.0,
    };
  }

  return {
    'correctRatio': correct / total,
    'wrongRatio': wrong / total,
    'blankRatio': blank / total,
  };
}
