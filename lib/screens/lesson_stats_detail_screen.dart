import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/plan_model.dart';
import '../providers/providers.dart';
import 'lesson_monthly_chart_screen.dart';

class LessonStatsDetailScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String lessonId;
  final String lessonName;

  const LessonStatsDetailScreen({
    super.key,
    required this.studentId,
    required this.lessonId,
    required this.lessonName,
  });

  @override
  ConsumerState<LessonStatsDetailScreen> createState() =>
      _LessonStatsDetailScreenState();
}

class _LessonStatsDetailScreenState
    extends ConsumerState<LessonStatsDetailScreen> {
  ActivityType _selectedActivityType = ActivityType.test;

  @override
  Widget build(BuildContext context) {
    final planRepository = ref.watch(planRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonName),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LessonMonthlyChartScreen(
                    studentId: widget.studentId,
                    lessonId: widget.lessonId,
                    lessonName: widget.lessonName,
                  ),
                ),
              );
            },
            tooltip: 'Aylık Grafik',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<ActivityType>(
              segments: const [
                ButtonSegment(value: ActivityType.test, label: Text('Test')),
                ButtonSegment(
                    value: ActivityType.study, label: Text('Konu Çalışması')),
              ],
              selected: {_selectedActivityType},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedActivityType = newSelection.first;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<Map<DateTime, Map<String, num>>>(
              stream: planRepository.getDailyStatsForLesson(
                widget.studentId,
                widget.lessonName,
                _selectedActivityType,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Bu kritere uygun istatistik bulunamadı.'));
                }

                final dailyStats = snapshot.data!;
                final sortedDates = dailyStats.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final stats = dailyStats[date]!;
                    final correct = stats['correct']?.toInt() ?? 0;
                    final incorrect = stats['incorrect']?.toInt() ?? 0;
                    final empty = stats['empty']?.toInt() ?? 0;
                    final successRate = stats['successRate']?.toDouble() ?? 0.0;
                    final totalQuestions = correct + incorrect + empty;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(DateFormat.yMMMMd('tr_TR').format(date)),
                        subtitle: Text(
                          '$totalQuestions Soru: $correct D - $incorrect Y - $empty B',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        trailing: Text(
                          '%${successRate.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: successRate >= 50
                                ? const Color.fromARGB(255, 131, 211, 133)
                                : const Color.fromARGB(255, 200, 110, 104),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
