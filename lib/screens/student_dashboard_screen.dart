import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plan_model.dart';
import '../models/user_model.dart';
import '../models/lesson_model.dart';
import '../providers/providers.dart';
import '../widgets/planner_base_view.dart';
import '../widgets/task_editor.dart';
import '../widgets/assign_coach_dialog.dart'; // YENİ EKLENDİ
import 'chat_list_screen.dart';
import 'edit_profile_screen.dart'; 

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FOCUS | Öğrenci Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: const _StudentDashboardBody(),
    );
  }
}

class _StudentDashboardBody extends ConsumerStatefulWidget {
  const _StudentDashboardBody();

  @override
  ConsumerState<_StudentDashboardBody> createState() => _StudentDashboardBodyState();
}

class _StudentDashboardBodyState extends ConsumerState<_StudentDashboardBody> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userModel = ref.watch(currentUserProvider).value;
    if (userModel == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Widget> widgetOptions = <Widget>[
      _HomeTab(student: userModel),
      _PlannerTab(student: userModel),
      const ChatListScreen(),
      _ProfileTab(user: userModel),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Planlayıcı'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Mesajlar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerStatefulWidget {
  final UserModel student;
  const _HomeTab({required this.student});

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  String _selectedPlanType = 'coach';

  Future<void> _updatePlanStatus(PlanModel plan, bool isCompleted) async {
    if (plan.id == null) return;
    try {
      await ref.read(planRepositoryProvider).updatePlanStatus(plan.id!, isCompleted);
      ref.invalidate(todaysPlansProvider(widget.student.id));
      ref.invalidate(weekPlansProvider((studentId: widget.student.id, weekDate: plan.date)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görev güncellenirken bir hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todaysPlansAsync = ref.watch(todaysPlansProvider(widget.student.id));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'coach', label: Text('Koç Planı'), icon: Icon(Icons.check_circle_outline)),
              ButtonSegment(value: 'student', label: Text('Benim Planım'), icon: Icon(Icons.edit_outlined)),
            ],
            selected: {_selectedPlanType},
            onSelectionChanged: (newSelection) => setState(() => _selectedPlanType = newSelection.first),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: todaysPlansAsync.when(
              data: (plans) {
                final filteredPlans = plans.where((p) => p.createdBy == _selectedPlanType).toList();
                if (filteredPlans.isEmpty) {
                  return const Center(child: Text('Bugün için planlanmış bir görev yok.'));
                }
                return ListView.builder(
                  itemCount: filteredPlans.length,
                  itemBuilder: (context, index) {
                    final plan = filteredPlans[index];
                    return _DailyPlanCard(
                      plan: plan,
                      onStatusChanged: (isCompleted) => _updatePlanStatus(plan, isCompleted),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Center(child: Text('Planlar yüklenemedi.')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyPlanCard extends StatelessWidget {
  final PlanModel plan;
  final ValueChanged<bool> onStatusChanged;

  const _DailyPlanCard({required this.plan, required this.onStatusChanged});

  String _buildTitle() {
    switch (plan.activityType) {
      case ActivityType.study: return '${plan.lessonName}: Konu Çalışması';
      case ActivityType.test: return '${plan.lessonName}: Test';
      case ActivityType.branchTrial: return '${plan.lessonName} Branş Denemesi';
      default: return plan.lessonName;
    }
  }

  String _buildSubtitle() {
    final details = plan.details;
    switch (plan.activityType) {
      case ActivityType.study:
        return details is StudyDetails ? '${details.durationMinutes} dakika' : 'Süre belirtilmemiş';
      case ActivityType.test:
      case ActivityType.branchTrial:
        return details is TestDetails ? '${details.plannedQuestionCount ?? 0} soru' : 'Soru sayısı belirtilmemiş';
      default: return plan.topicName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: CheckboxListTile(
        value: plan.isCompleted,
        onChanged: (newValue) => newValue != null ? onStatusChanged(newValue) : null,
        title: Text(_buildTitle()),
        subtitle: Text(_buildSubtitle()),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}

class _PlannerTab extends ConsumerStatefulWidget {
  final UserModel student;
  const _PlannerTab({required this.student});

  @override
  ConsumerState<_PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends ConsumerState<_PlannerTab> {
  late DateTime _currentWeek;

  @override
  void initState() {
    super.initState();
    _currentWeek = DateTime.now();
  }

  Future<void> _savePlan(PlanModel plan) async {
    await ref.read(planRepositoryProvider).addPlan(plan);
    ref.invalidate(weekPlansProvider((studentId: widget.student.id, weekDate: _currentWeek)));
    ref.invalidate(weekPlansProvider((studentId: widget.student.id, weekDate: plan.date)));
    ref.invalidate(todaysPlansProvider(widget.student.id));
  }

  Future<void> _deletePlan(PlanModel plan) async {
    if (plan.id != null) {
      await ref.read(planRepositoryProvider).plansRef.doc(plan.id!).delete();
      ref.invalidate(weekPlansProvider((studentId: widget.student.id, weekDate: _currentWeek)));
      ref.invalidate(weekPlansProvider((studentId: widget.student.id, weekDate: plan.date)));
      ref.invalidate(todaysPlansProvider(widget.student.id));
    }
  }

  void _showTaskEditor({PlanModel? plan, required int dayIndex, required List<LessonModel> tyt, required List<LessonModel> ayt}) {
     showModalBottomSheet(
      context: context, isScrollControlled: true, builder: (context) => TaskEditor(
          plan: plan, dayIndex: dayIndex, student: widget.student,
          onSavePlan: _savePlan,
          getDateForDayIndex: (index) => _getDateForDayIndex(index, referenceDate: _currentWeek),
          createdBy: 'student', 
          tytLessons: tyt, aytLessons: ayt,
          onFetchTopics: (lessonId) => ref.read(planRepositoryProvider).getTopicsForLesson(widget.student.examType!, lessonId),
        ),
      );
  }
  
  DateTime _getDateForDayIndex(int index, {DateTime? referenceDate}) {
    final refDate = referenceDate ?? _currentWeek;
    final startOfWeek = refDate.subtract(Duration(days: refDate.weekday - 1));
    return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).add(Duration(days: index));
  }
  
  @override
  Widget build(BuildContext context) {
    final weekPlansAsync = ref.watch(weekPlansProvider((studentId: widget.student.id, weekDate: _currentWeek)));
    final lessonsAsync = ref.watch(lessonsForUserProvider);

    return Column(
      children: [
        Expanded(
          child: Builder(
            builder: (context) {
              if (weekPlansAsync.isLoading || lessonsAsync.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (weekPlansAsync.hasError || lessonsAsync.hasError) {
                return Center(child: Text('Veriler yüklenirken bir hata oluştu: ${weekPlansAsync.error ?? lessonsAsync.error}'));
              }

              final allLessons = lessonsAsync.value!;
              final allPlans = weekPlansAsync.value!;

              final tytLessons = allLessons.where((l) => l.type == 'TYT').toList();
              final aytLessons = allLessons.where((l) => l.type == 'AYT').toList();

              final dailyPlans = <int, List<PlanModel>>{};
              for (final plan in allPlans) {
                final dayIndex = plan.date.weekday - 1;
                dailyPlans.putIfAbsent(dayIndex, () => []).add(plan);
              }
              dailyPlans.forEach((key, value) => value.sort((a, b) => a.createdAt.compareTo(b.createdAt)));

              return PlannerBaseView(
                student: widget.student,
                currentUserType: 'student',
                dailyPlans: dailyPlans,
                isLoading: { for(int i=0; i<7; i++) i: false },
                currentWeek: _currentWeek,
                onEditTask: (plan, dayIndex) => _showTaskEditor(plan: plan, dayIndex: dayIndex, tyt: tytLessons, ayt: aytLessons),
                onDeletePlan: _deletePlan,
                onAddNewTask: (dayIndex) => _showTaskEditor(dayIndex: dayIndex, tyt: tytLessons, ayt: aytLessons),
                onGoToNextWeek: () => setState(() => _currentWeek = _currentWeek.add(const Duration(days: 7))),
                onGoToPreviousWeek: () => setState(() => _currentWeek = _currentWeek.subtract(const Duration(days: 7))),
                getDateForDayIndex: _getDateForDayIndex,
                onRefresh: () async => ref.invalidate(weekPlansProvider((studentId: widget.student.id, weekDate: _currentWeek))),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  final UserModel user;
  const _ProfileTab({required this.user});

  void _showAssignCoachDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AssignCoachDialog(user: user),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             CircleAvatar(
              radius: 50,
              backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SelectableText(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Kullanıcı ID', user.id, isCopiable: true),
            _buildCoachSection(context, ref),
            _buildDetailRow(context, 'Sınav Türü', user.examType),
            _buildDetailRow(context, 'Lise', user.highSchool),
            _buildDetailRow(context, 'Hedef Bölüm', user.targetMajor),
            _buildDetailRow(context, 'Hedef Sıralama', user.targetRank),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Profili Düzenle'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachSection(BuildContext context, WidgetRef ref) {
    if (user.coachId == null || user.coachId!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: OutlinedButton.icon(
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text('Koç ile Eşleş'),
          onPressed: () => _showAssignCoachDialog(context, ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
            side: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
      );
    } else {
      final coachAsyncValue = ref.watch(assignedCoachProvider(user.coachId!));
      return coachAsyncValue.when(
        data: (coach) => _buildDetailRow(context, 'Atanan Koç', coach?.name ?? 'Koç bulunamadı'),
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => _buildDetailRow(context, 'Hata', 'Koç bilgisi alınamadı'),
      );
    }
  }

  Widget _buildDetailRow(BuildContext context, String title, String? value, {bool isCopiable = false}) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: SelectableText(value)),
          if (isCopiable)
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kopyalandı!')),
                );
              },
            ),
        ],
      ),
    );
  }
}
