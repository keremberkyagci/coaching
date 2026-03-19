// ============================================================
// lib/screens/student_dashboard_screen.dart — Öğrenci ana paneli
//
// Uygulamanın en büyük ekranı. 4 sekme içerir:
//   1. Ana Sayfa (_HomeTab)     : Bugünkü planlar + koç/öğrenci plan geçişi + istatistikler
//   2. Planlayıcı (_PlannerTab) : Haftalık plan görünümü (PlannerBaseView widget'ı)
//   3. Mesajlar (ChatListScreen): Sohbet listesi (ayrı ekran olarak entegre)
//   4. Profil (_ProfileTab)     : Öğrenci bilgileri, koç bağlantısı, profil düzenleme
//
// Önemli mantıklar:
//   - initState'te tüm konular tek seferde yüklenir → topicProvider global cache'e yazılır
//   - _HomeTab: SegmentedButton ile Koç Planı / Benim Planım / İstatistikler arasında geçiş
//   - _DailyPlanCard: Test/Branş denemesi tamamlanınca TaskResultDialog açılır (D/Y/B girişi)
//   - _PlannerTab: Hafta navigasyonu (ileri/geri) + TaskEditor modal ile görev ekleme/düzenleme
//   - _ProfileTab: Kullanıcı ID kopyalanabilir (yeni sohbet için karşı taraf ID'si gerekli)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plan_model.dart';
import '../models/user_model.dart';
import '../models/lesson_model.dart';
import '../providers/providers.dart';
import '../widgets/planner/planner_base_view.dart';
import '../widgets/planner/task_editor.dart';
import '../widgets/dialogs/assign_coach_dialog.dart';
import '../widgets/dialogs/task_result_dialog.dart';
import '../widgets/statistics/student_stats_view.dart';
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
  ConsumerState<_StudentDashboardBody> createState() =>
      _StudentDashboardBodyState();
}

class _StudentDashboardBodyState extends ConsumerState<_StudentDashboardBody> {
  int _selectedIndex = 0;
  bool _topicsLoaded = false;

  @override
  void initState() {
    super.initState();
    // Öğrenci dashboard'a girdiği gibi arka planda tüm konuları + değerlendirmelerini sadece 1 kez çekiyoruz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllTopics();
    });
  }

  Future<void> _loadAllTopics() async {
    final userModel = ref.read(currentUserProvider).value;
    if (userModel == null || _topicsLoaded) return;

    final repo = ref.read(planRepositoryProvider);
    final allTopics = await repo.getAllTopicsForStudent(userModel.id);

    // Global cache'e yaz
    ref.read(topicProvider.notifier).setTopics(allTopics);
    _topicsLoaded = true;
  }

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
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Planlayıcı'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined), label: 'Mesajlar'),
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

  Future<void> _handlePlanToggle(PlanModel plan, bool isCompleted) async {
    if (plan.id == null) return;

    if (isCompleted &&
        (plan.activityType == ActivityType.test ||
            plan.activityType == ActivityType.branchTrial)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => TaskResultDialog(
          plan: plan,
        ),
      );
    } else if (isCompleted) {
      await ref.read(planRepositoryProvider).updatePlanStatus(plan.id!, true);
      _refreshData(plan.date);
    } else {
      await ref.read(planRepositoryProvider).detachSessionFromPlan(plan.id!);
      _refreshData(plan.date);
    }
  }

  void _refreshData(DateTime date) {
    ref.invalidate(todaysPlansProvider(widget.student.id));
    ref.invalidate(
        weekPlansProvider((studentId: widget.student.id, weekDate: date)));
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
              ButtonSegment(
                  value: 'coach',
                  label: Text('Koç Planı'),
                  icon: Icon(Icons.check_circle_outline)),
              ButtonSegment(
                  value: 'student',
                  label: Text('Benim Planım'),
                  icon: Icon(Icons.edit_outlined)),
              ButtonSegment(
                  value: 'stats',
                  label: Text('İstatistikler'),
                  icon: Icon(Icons.analytics_outlined)),
            ],
            selected: {_selectedPlanType},
            onSelectionChanged: (newSelection) =>
                setState(() => _selectedPlanType = newSelection.first),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildContent(todaysPlansAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AsyncValue<List<PlanModel>> todaysPlansAsync) {
    if (_selectedPlanType == 'stats') {
      return StudentStatsView(studentId: widget.student.id);
    }

    return todaysPlansAsync.when(
      data: (plans) {
        final filteredPlans =
            plans.where((p) => p.createdBy == _selectedPlanType).toList();
        if (filteredPlans.isEmpty) {
          return const Center(
              child: Text('Bugün için planlanmış bir görev yok.'));
        }
        return ListView.builder(
          itemCount: filteredPlans.length,
          itemBuilder: (context, index) {
            final plan = filteredPlans[index];
            return _DailyPlanCard(
              plan: plan,
              onStatusChanged: (isCompleted) =>
                  _handlePlanToggle(plan, isCompleted),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Center(child: Text('Planlar yüklenemedi.')),
    );
  }
}

class _DailyPlanCard extends ConsumerWidget {
  final PlanModel plan;
  final ValueChanged<bool> onStatusChanged;

  const _DailyPlanCard({
    required this.plan,
    required this.onStatusChanged,
  });

  String _buildTitle() {
    switch (plan.activityType) {
      case ActivityType.study:
        return '${plan.lessonName}: Konu Çalışması';
      case ActivityType.test:
        return '${plan.lessonName}: Test';
      case ActivityType.branchTrial:
        return '${plan.lessonName} Branş Denemesi';
      default:
        return plan.lessonName;
    }
  }

  String _buildBaseSubtitle() {
    final details = plan.details;
    String text = plan.topicName;

    if (plan.activityType == ActivityType.study && details is StudyDetails) {
      text += ' (${details.durationMinutes} dk)';
    } else if ((plan.activityType == ActivityType.test ||
            plan.activityType == ActivityType.branchTrial) &&
        details is TestDetails) {
      text += ' (${details.plannedQuestionCount ?? 0} soru)';
    }

    return text;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseSubtitle = _buildBaseSubtitle();

    if (plan.sessionId == null || plan.sessionId!.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: CheckboxListTile(
          value: plan.isCompleted,
          onChanged: (newValue) =>
              newValue != null ? onStatusChanged(newValue) : null,
          title: Text(_buildTitle()),
          subtitle: Text(baseSubtitle),
          controlAffinity: ListTileControlAffinity.trailing,
        ),
      );
    }

    final sessionAsync = ref.watch(
      sessionByIdProvider(plan.sessionId!),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: CheckboxListTile(
        value: plan.isCompleted,
        onChanged: (newValue) =>
            newValue != null ? onStatusChanged(newValue) : null,
        title: Text(_buildTitle()),
        subtitle: sessionAsync.when(
          data: (session) {
            if (session == null) return Text(baseSubtitle);

            final correct = session.correct ?? 0;
            final wrong = session.wrong ?? 0;
            final blank = session.blank ?? 0;

            return Text('$baseSubtitle - ${correct}D ${wrong}Y ${blank}B');
          },
          loading: () => Text(baseSubtitle),
          error: (_, __) => Text(baseSubtitle),
        ),
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
    ref.invalidate(weekPlansProvider(
        (studentId: widget.student.id, weekDate: _currentWeek)));
    ref.invalidate(
        weekPlansProvider((studentId: widget.student.id, weekDate: plan.date)));
    ref.invalidate(todaysPlansProvider(widget.student.id));
  }

  Future<void> _deletePlan(PlanModel plan) async {
    if (plan.id != null) {
      await ref.read(planRepositoryProvider).plansRef.doc(plan.id!).delete();
      ref.invalidate(weekPlansProvider(
          (studentId: widget.student.id, weekDate: _currentWeek)));
      ref.invalidate(weekPlansProvider(
          (studentId: widget.student.id, weekDate: plan.date)));
      ref.invalidate(todaysPlansProvider(widget.student.id));
    }
  }

  void _showTaskEditor(
      {PlanModel? plan,
      required int dayIndex,
      required List<LessonModel> tyt,
      required List<LessonModel> ayt}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TaskEditor(
        plan: plan,
        dayIndex: dayIndex,
        student: widget.student,
        onSavePlan: _savePlan,
        getDateForDayIndex: (index) =>
            _getDateForDayIndex(index, referenceDate: _currentWeek),
        createdBy: 'student',
        tytLessons: tyt,
        aytLessons: ayt,
        onFetchTopics: (lessonId) => ref
            .read(planRepositoryProvider)
            .getTopicsForLesson(widget.student.examType!, lessonId),
      ),
    );
  }

  DateTime _getDateForDayIndex(int index, {DateTime? referenceDate}) {
    final refDate = referenceDate ?? _currentWeek;
    final startOfWeek = refDate.subtract(Duration(days: refDate.weekday - 1));
    return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)
        .add(Duration(days: index));
  }

  @override
  Widget build(BuildContext context) {
    final weekPlansAsync = ref.watch(weekPlansProvider(
        (studentId: widget.student.id, weekDate: _currentWeek)));
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
                return Center(
                    child: Text(
                        'Veriler yüklenirken bir hata oluştu: ${weekPlansAsync.error ?? lessonsAsync.error}'));
              }

              final allLessons = lessonsAsync.value!;
              final allPlans = weekPlansAsync.value!;

              final tytLessons =
                  allLessons.where((l) => l.type == 'TYT').toList();
              final aytLessons =
                  allLessons.where((l) => l.type == 'AYT').toList();

              final dailyPlans = <int, List<PlanModel>>{};
              for (final plan in allPlans) {
                final dayIndex = plan.date.weekday - 1;
                dailyPlans.putIfAbsent(dayIndex, () => []).add(plan);
              }
              dailyPlans.forEach((key, value) =>
                  value.sort((a, b) => a.createdAt.compareTo(b.createdAt)));

              return PlannerBaseView(
                student: widget.student,
                currentUserType: 'student',
                dailyPlans: dailyPlans,
                isLoading: {for (int i = 0; i < 7; i++) i: false},
                currentWeek: _currentWeek,
                onEditTask: (dynamic plan, int dayIndex) => _showTaskEditor(
                    plan: plan as PlanModel,
                    dayIndex: dayIndex,
                    tyt: tytLessons,
                    ayt: aytLessons),
                onDeletePlan: _deletePlan,
                onAddNewTask: (dayIndex) => _showTaskEditor(
                    dayIndex: dayIndex, tyt: tytLessons, ayt: aytLessons),
                onGoToNextWeek: () => setState(() =>
                    _currentWeek = _currentWeek.add(const Duration(days: 7))),
                onGoToPreviousWeek: () => setState(() => _currentWeek =
                    _currentWeek.subtract(const Duration(days: 7))),
                getDateForDayIndex: _getDateForDayIndex,
                onRefresh: () async => ref.invalidate(weekPlansProvider(
                    (studentId: widget.student.id, weekDate: _currentWeek))),
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

            Text(
              user.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SelectableText(
              user.email,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
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
                    MaterialPageRoute(
                        builder: (context) => EditProfileScreen(user: user)),
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
        data: (coach) => _buildDetailRow(
            context, 'Atanan Koç', coach?.name ?? 'Koç bulunamadı'),
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) =>
            _buildDetailRow(context, 'Hata', 'Koç bilgisi alınamadı'),
      );
    }
  }

  Widget _buildDetailRow(BuildContext context, String title, String? value,
      {bool isCopiable = false}) {
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
