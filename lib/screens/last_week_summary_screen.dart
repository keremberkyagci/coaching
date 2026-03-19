// ============================================================
// lib/screens/last_week_summary_screen.dart — Haftalık özet ekranı
//
// Belirli bir öğrencinin geçmiş haftalarının plan özetini gösterir.
// Koç tarafından StudentDetailScreen üzerinden açılır.
//
// Özellikler:
//   - 7 günlük TabBar ile her güne ayrı sekme (Pzt → Paz)
//   - Her sekmede "Öğrencinin Planı" ve "Koçun Planı" ayrı bölümlerde
//   - Görevler tamamlanma durumuna göre ✓ veya ○ ikonu ile gösterilir
//   - İleri/geri hafta navigasyonu: _goToPreviousWeek / _goToNextWeek
//   - varsayılan olarak geçen haftayı açar (DateTime.now() - 7 gün)
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/plan_model.dart';
import '../providers/providers.dart';

class LastWeekSummaryScreen extends ConsumerStatefulWidget {
  final UserModel student;

  const LastWeekSummaryScreen({super.key, required this.student});

  @override
  ConsumerState<LastWeekSummaryScreen> createState() => LastWeekSummaryScreenState();
}

class LastWeekSummaryScreenState extends ConsumerState<LastWeekSummaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  late DateTime _currentWeek;
  Stream<List<PlanModel>>? _plansStream;

  @override
  void initState() {
    super.initState();
    _currentWeek = DateTime.now().subtract(const Duration(days: 7));
    _tabController = TabController(length: 7, vsync: this, initialIndex: DateTime.now().weekday - 1);
    _setupPlansStream();
  }
  
  void _setupPlansStream() {
    final startOfWeek = _currentWeek.subtract(Duration(days: _currentWeek.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    _plansStream = ref.read(planRepositoryProvider).getPlansForStudent(
        widget.student.id, startOfWeek, endOfWeek);
    setState(() {});
  }

  DateTime _getDateForDayIndex(int index) {
    final startOfWeek = _currentWeek.subtract(Duration(days: _currentWeek.weekday - 1));
    return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)
        .add(Duration(days: index));
  }

  String _getWeekDateRange(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final DateFormat formatter = DateFormat('d MMMM', 'tr_TR');
    return '${formatter.format(startOfWeek)} - ${formatter.format(endOfWeek)}';
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeek = _currentWeek.subtract(const Duration(days: 7));
      _setupPlansStream();
    });
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeek = _currentWeek.add(const Duration(days: 7));
      _setupPlansStream();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.name} | Hafta Özeti'),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _goToPreviousWeek),
                Text(
                  _getWeekDateRange(_currentWeek),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _goToNextWeek),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: List.generate(7, (index) {
              final dayDate = _getDateForDayIndex(index);
              final dayName = _days[index];
              final dateText = DateFormat('dd/MM', 'tr_TR').format(dayDate);
              return Tab(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(dateText, style: const TextStyle(fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(dayName),
                  ],
                ),
              );
            }),
          ),
          Expanded(
            child: StreamBuilder<List<PlanModel>>(
              stream: _plansStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final allPlans = snapshot.data ?? [];
                final dailyPlans = <int, List<PlanModel>>{};
                for (var plan in allPlans) {
                  dailyPlans.putIfAbsent(plan.date.weekday - 1, () => []).add(plan);
                }

                return TabBarView(
                  controller: _tabController,
                  children: List.generate(7, (dayIndex) {
                    final plansForDay = dailyPlans[dayIndex] ?? [];
                    final studentPlans = plansForDay.where((p) => p.createdBy == 'student').toList();
                    final coachPlans = plansForDay.where((p) => p.createdBy == 'coach').toList();

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPlanSection('Öğrencinin Planı', studentPlans),
                          const SizedBox(height: 24),
                          _buildPlanSection('Koçun Planı', coachPlans),
                        ],
                      ),
                    );
                  }),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSection(String title, List<PlanModel> plans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        if (plans.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
                child: Text('Bu gün için plan bulunmuyor.',
                    style: TextStyle(color: Colors.grey))),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            return ListTile(
              title: Text(plan.topicName),
              // DÜZELTİLDİ: Gereksiz null-check kaldırıldı.
              subtitle: Text(plan.lessonName),
              trailing: Icon(
                plan.isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: plan.isCompleted
                    ? Colors.green
                    : Colors.grey,
              ),
            );
          },
        ),
      ],
    );
  }
}
