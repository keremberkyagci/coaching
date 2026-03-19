import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/monthly_performance_model.dart';

class PerformanceBarChart extends StatelessWidget {
  final List<MonthlyPerformance> data;

  const PerformanceBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Görüntülenecek veri bulunamadı.'));
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding:
            const EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
        child: BarChart(
          BarChartData(
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) =>
                    Colors.blueGrey.withValues(alpha: 0.9),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final monthlyData = data[group.x];
                  return BarTooltipItem(
                    '${monthlyData.month}\n',
                    const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: 'Doğru: ${monthlyData.correctPercentage}\n',
                        style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.normal),
                      ),
                      TextSpan(
                        text: 'Yanlış: ${monthlyData.wrongPercentage}\n',
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.normal),
                      ),
                      TextSpan(
                        text: 'Boş: ${monthlyData.blankPercentage}',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.normal),
                      ),
                    ],
                  );
                },
              ),
            ),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              show: true,
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < data.length) {
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(data[index].month,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 0.2, // 20% intervals
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text('%${(value * 100).toInt()}',
                          style: const TextStyle(fontSize: 10)),
                    );
                  },
                  reservedSize: 42,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            maxY: 1.0, // Because the max combined ratio is exactly 1.0 (100%)
            barGroups: List.generate(data.length, (index) {
              final e = data[index];
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: 1.0,
                    width: 32,
                    borderRadius: BorderRadius.circular(4),
                    rodStackItems: [
                      BarChartRodStackItem(
                        0,
                        e.correctRatio,
                        Colors.green,
                      ),
                      BarChartRodStackItem(
                        e.correctRatio,
                        e.correctRatio + e.blankRatio,
                        Colors.grey,
                      ),
                      BarChartRodStackItem(
                        e.correctRatio + e.blankRatio,
                        1.0, // The remaining rest goes up to 1.0
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

// Örnek Kullanım Widget'ı
class PerformanceChartPage extends StatelessWidget {
  const PerformanceChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<MonthlyPerformance> sampleData = [
      MonthlyPerformance.fromStats(
          month: 'Oca', totalCorrect: 150, totalWrong: 30, totalBlank: 20),
      MonthlyPerformance.fromStats(
          month: 'Şub', totalCorrect: 180, totalWrong: 20, totalBlank: 10),
      MonthlyPerformance.fromStats(
          month: 'Mar', totalCorrect: 140, totalWrong: 40, totalBlank: 20),
      MonthlyPerformance.fromStats(
          month: 'Nis', totalCorrect: 200, totalWrong: 10, totalBlank: 5),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Performans Grafiği')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Aylık Doğru/Yanlış/Boş Oranları',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            PerformanceBarChart(data: sampleData),
            const SizedBox(height: 20),
            _buildLegend(),
          ],
        ),
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
