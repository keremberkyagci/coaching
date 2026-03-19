// ============================================================
// lib/screens/lesson_monthly_chart_screen.dart — Aylık performans ve konu değerlendirme ekranı
//
// Tek bir ders için son 6 aylık performans grafiği + konu yetkinlik değerlendirmesi.
// StudentDetailScreen veya studentStatsView'dan lessonId ile açılır.
//
// Bileşenler:
//   - PerformanceBarChart        : Son 6 ayın D/Y/B dağılım grafiği (fl_chart)
//   - _buildLegend               : Grafik renk açıklaması
//   - generatePerformanceComment : Trend yorumu (artış/düşüş/stabil)
//   - _PerformanceInsightCard    : Detaylı analiz kartı (trend + öneri)
//   - StarRating                 : Her konu için 1-5 yıldız derecelendirme
//                                  topicProvider.notifier.updateRating() ile anlık güncelleme
//
// Konu listesi: topicProvider global cache'den filtrelenir (lessonId eşleşmesi)
//              Konular 'group' alanına göre başlıklar altında gruplanır
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monthly_performance_model.dart';
import '../providers/providers.dart';
import '../widgets/statistics/performance_line_chart.dart';

class LessonMonthlyChartScreen extends ConsumerWidget {
  final String studentId;
  final String lessonId;
  final String lessonName;

  const LessonMonthlyChartScreen({
    super.key,
    required this.studentId,
    required this.lessonId,
    required this.lessonName,
  });

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(
      monthlyPerformanceForLessonProvider(
        (studentId: studentId, lessonId: lessonId),
      ),
    );

    // Bütün konuları önbellekten dinliyoruz ve sadece bu derse ait olanları filtreliyoruz
    final allTopics = ref.watch(topicProvider);
    final lessonTopics =
        allTopics.where((t) => t.lessonId == lessonId).toList();

    // YENİ: Firebase üzerindeki 'group' olsun ya da olmasın, tüm konuları mutlaka 'order' (sıra) değerine göre diziyoruz.
    lessonTopics.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    return Scaffold(
      appBar: AppBar(title: Text('$lessonName İstatistikleri')),
      body: monthlyAsync.when(
        data: (data) {
          final comment = generatePerformanceComment(data);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Aylık Performans Grafiği',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                PerformanceBarChart(data: data),
                const SizedBox(height: 24),
                _buildLegend(),
                const SizedBox(height: 16),
                Text(
                  comment,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 32),
                _PerformanceInsightCard(data: data),

                // YENİ: Konu Değerlendirme (Rating) Kısmı
                const SizedBox(height: 32),
                const Text(
                  'Konu Yeterlilik Seviyen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kendini yetersiz hissettiğin konulara 1-2 yıldız, iyi olduğun konulara 4-5 yıldız vererek sana özel reçete sunmamıza yardımcı ol.',
                  style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                ),
                const SizedBox(height: 16),
                if (lessonTopics.isEmpty)
                  const Center(
                      child: Text(
                          "Bu derse ait konu bulunamadı veya henüz yükleniyor.",
                          style: TextStyle(fontStyle: FontStyle.italic)))
                else
                  ...(() {
                    final List<Widget> items = [];
                    String? lastGroup;

                    for (final topic in lessonTopics) {
                      final currentGroup = topic.group?.trim() ?? '';

                      if (currentGroup.isNotEmpty &&
                          currentGroup != lastGroup) {
                        items.add(
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 16.0, bottom: 8.0, left: 4.0),
                            child: Text(
                              currentGroup,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        );
                        lastGroup = currentGroup;
                      }

                      items.add(
                        Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            title: Text(topic.name,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                            trailing: StarRating(
                              rating: topic.rating ?? 0,
                              onChanged: (value) {
                                // Backend + State Update
                                ref
                                    .read(topicProvider.notifier)
                                    .updateRating(studentId, topic.id!, value);
                              },
                            ),
                          ),
                        ),
                      );
                    }
                    return items;
                  })(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Doğru', Colors.green),
        const SizedBox(width: 16),
        _legendItem('Yanlış', Colors.red),
        const SizedBox(width: 16),
        _legendItem('Boş', Colors.grey),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class StarRating extends StatelessWidget {
  final int rating;
  final Function(int) onChanged;

  const StarRating({super.key, required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return InkWell(
          onTap: () => onChanged(index + 1),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 24,
            ),
          ),
        );
      }),
    );
  }
}

class _PerformanceInsightCard extends StatelessWidget {
  final List<MonthlyPerformance> data;

  const _PerformanceInsightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
              'Yeterli veri toplandığında performans analizi burada görünecek.'),
        ),
      );
    }

    final latest = data.last;
    final previous = data[data.length - 2];

    final correctTrend = latest.correctRatio - previous.correctRatio;
    final wrongTrend = latest.wrongRatio - previous.wrongRatio;

    String correctComment = "Doğru oranınız stabil.";
    IconData correctIcon = Icons.remove;
    Color correctColor = Colors.grey;

    if (correctTrend > 0.05) {
      correctComment = "Doğru oranınız artıyor, harika!";
      correctIcon = Icons.trending_up;
      correctColor = Colors.green;
    } else if (correctTrend < -0.05) {
      correctComment = "Doğru oranınızda bir düşüş var.";
      correctIcon = Icons.trending_down;
      correctColor = Colors.red;
    }

    String wrongComment = "Yanlış oranınız kontrol altında.";
    IconData wrongIcon = Icons.check_circle_outline;
    Color wrongColor = Colors.blue;

    if (wrongTrend > 0.05) {
      wrongComment = "Yanlış sayınız artıyor, dikkat!";
      wrongIcon = Icons.warning_amber_rounded;
      wrongColor = Colors.orange;
    } else if (wrongTrend < -0.05) {
      wrongComment = "Yanlış oranınız azalıyor, çok iyi.";
      wrongIcon = Icons.thumb_up_alt_outlined;
      wrongColor = Colors.green;
    }

    String suggestion = "Daha fazla deneme çözerek pratik yapabilirsin.";
    if (latest.blankRatio > 0.2) {
      suggestion = "Boş bıraktığın konuları tekrar gözden geçirmelisin.";
    } else if (latest.correctRatio > 0.8) {
      suggestion =
          "Hedeflerini büyütebilir veya zor seviye sorulara geçebilirsin.";
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Detaylı Analiz',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInsightItem(correctComment, correctIcon, correctColor),
            const SizedBox(height: 12),
            _buildInsightItem(wrongComment, wrongIcon, wrongColor),
            const SizedBox(height: 12),
            _buildInsightItem(
                suggestion, Icons.lightbulb_outline, Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
