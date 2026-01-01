// lib/widgets/student_stats_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app_v2_final/models/user_model.dart';
import 'package:focus_app_v2_final/providers/providers.dart';

/// Öğrencinin derslere göre test istatistiklerini gösteren, Riverpod ile çalışan modern widget.
class StudentStatsView extends ConsumerWidget {
  final UserModel student;

  const StudentStatsView({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Merkezi provider'dan öğrencinin istatistik stream'ini izliyoruz.
    final statsAsyncValue = ref.watch(studentStatsProvider(student.id));

    // AsyncValue.when, Stream'in 3 durumunu (veri, yükleniyor, hata) yönetir.
    return statsAsyncValue.when(
      data: (statsList) {
        if (statsList.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'İstatistiklerini görmek için planından görevleri tamamlamaya başla!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }
        
        // Gelen listeyi ders ismine göre sıralıyoruz.
        statsList.sort((a, b) => a.lessonName.compareTo(b.lessonName));

        return ListView.builder(
          itemCount: statsList.length,
          itemBuilder: (context, index) {
            final stats = statsList[index];
            final correct = stats.totalCorrect;
            final incorrect = stats.totalIncorrect;
            final empty = stats.totalEmpty;
            final total = correct + incorrect;
            final successRate = total == 0 ? 0.0 : (correct / total) * 100;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                title: Text(
                  stats.lessonName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text('$correct Doğru, $incorrect Yanlış, $empty Boş'),
                trailing: CircleAvatar(
                  radius: 30,
                  backgroundColor: successRate >= 50 ? Colors.green.shade100 : Colors.red.shade100,
                  child: Text(
                    '%${successRate.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: successRate >= 50 ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Hata: $error')),
    );
  }
}