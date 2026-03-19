import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/lesson_model.dart';
import '../../providers/providers.dart';
import '../../screens/lesson_monthly_chart_screen.dart';

class StudentStatsView extends ConsumerWidget {
  final String studentId;

  const StudentStatsView({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tüm dersleri getir
    final allLessonsAsync = ref.watch(allLessonsProvider);

    return allLessonsAsync.when(
      data: (lessons) {
        if (lessons.isEmpty) {
          return const Center(child: Text('Görüntülenecek ders bulunamadı.'));
        }

        // Ders isimlerine veya ID'sine göre TYT / AYT ayrımı yapıyoruz
        // (Eğer modelde examType dönüyorsa lesson.type == 'TYT' de kullanılabilir)
        final tytLessons = lessons
            .where((l) =>
                l.name.toUpperCase().contains('TYT') ||
                (l.type?.toUpperCase().contains('TYT') ?? false))
            .toList();

        final aytLessons = lessons
            .where((l) =>
                !tytLessons.contains(l) &&
                (l.name.toUpperCase().contains('AYT') ||
                    (l.type?.toUpperCase().contains('AYT') ?? false)))
            .toList();

        // TYT veya AYT olarak sınıflandırılamayan genel dersler (olasıysa)
        final otherLessons = lessons
            .where((l) => !tytLessons.contains(l) && !aytLessons.contains(l))
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (tytLessons.isNotEmpty) ...[
              _buildSectionHeader(
                  context, '1. TYT İstatistikleri', Colors.blueGrey),
              ...tytLessons.map((lesson) => _buildLessonItem(context, lesson)),
              const SizedBox(height: 24),
            ],
            if (aytLessons.isNotEmpty) ...[
              _buildSectionHeader(
                  context, '2. AYT İstatistikleri', Colors.deepPurple),
              ...aytLessons.map((lesson) => _buildLessonItem(context, lesson)),
              const SizedBox(height: 24),
            ],
            if (otherLessons.isNotEmpty) ...[
              _buildSectionHeader(context, 'Diğer İstatistikler', Colors.grey),
              ...otherLessons
                  .map((lesson) => _buildLessonItem(context, lesson)),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text("Hata: $e")),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Row(
        children: [
          Icon(Icons.bar_chart, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonItem(BuildContext context, LessonModel lesson) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(lesson.name,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.show_chart, color: Colors.blueGrey),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LessonMonthlyChartScreen(
                studentId: studentId,
                lessonId: lesson.id!,
                lessonName: lesson.name,
              ),
            ),
          );
        },
      ),
    );
  }
}
