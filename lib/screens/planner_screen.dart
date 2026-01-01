import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/plan_model.dart';
import '../models/lesson_model.dart';
import '../models/topic_model.dart';
import '../providers/providers.dart';
import '../widgets/planner_base_view.dart';
import '../widgets/task_editor.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  final UserModel student;

  const PlannerScreen({super.key, required this.student});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  late DateTime _currentWeek;
  List<LessonModel> _tytLessons = [];
  List<LessonModel> _aytLessons = [];

  @override
  void initState() {
    super.initState();
    _currentWeek = DateTime.now();
    Future.microtask(_loadAllLessons);
  }

  Future<void> _loadAllLessons() async {
    final studentExamType = widget.student.examType;
    if (studentExamType == null || studentExamType.isEmpty) return;

    final allLessons = await ref.read(planRepositoryProvider).getLessonsForExam(studentExamType);
    if (mounted) {
      setState(() {
        _tytLessons = allLessons.where((l) => l.type == 'TYT').toList();
        _aytLessons = allLessons.where((l) => l.type == 'AYT').toList();
      });
    }
  }

  Future<List<TopicModel>> _fetchTopicsForLesson(String lessonId) async {
    final studentExamType = widget.student.examType;
    if (studentExamType == null || studentExamType.isEmpty) return [];
    return ref.read(planRepositoryProvider).getTopicsForLesson(studentExamType, lessonId);
  }

  Future<void> _savePlan(PlanModel plan) async {
    await ref.read(planRepositoryProvider).addPlan(plan);
  }

  Future<void> _deletePlan(PlanModel plan) async {
    if (plan.id != null) {
      await ref.read(planRepositoryProvider).plansRef.doc(plan.id!).delete();
    }
  }

  void _showTaskEditor({PlanModel? plan, required int dayIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TaskEditor(
        plan: plan,
        dayIndex: dayIndex,
        student: widget.student,
        onSavePlan: _savePlan,
        getDateForDayIndex: (index) => _getDateForDayIndex(index, referenceDate: _currentWeek),
        createdBy: ref.read(currentUserProvider).value?.userType == UserType.coach ? 'coach' : 'student',
        tytLessons: _tytLessons,
        aytLessons: _aytLessons,
        onFetchTopics: _fetchTopicsForLesson,
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
    final currentUser = ref.watch(currentUserProvider).value;
    final weekPlansAsync = ref.watch(weekPlansProvider((studentId: widget.student.id, weekDate: _currentWeek)));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.name} | Planlayıcı'),
      ),
      body: weekPlansAsync.when(
        data: (plans) {
          final dailyPlans = <int, List<PlanModel>>{};
          for (final plan in plans) {
            final dayIndex = plan.date.weekday - 1;
            dailyPlans.putIfAbsent(dayIndex, () => []).add(plan);
          }
          dailyPlans.forEach((key, value) => value.sort((a, b) => a.createdAt.compareTo(b.createdAt)));

          return PlannerBaseView(
            student: widget.student,
            currentUserType: currentUser?.userType.name,
            dailyPlans: dailyPlans,
            isLoading: { for(int i=0; i<7; i++) i: false },
            currentWeek: _currentWeek,
            onEditTask: (plan, dayIndex) => _showTaskEditor(plan: plan, dayIndex: dayIndex),
            onDeletePlan: _deletePlan,
            onAddNewTask: (dayIndex) => _showTaskEditor(dayIndex: dayIndex),
            onGoToNextWeek: () => setState(() => _currentWeek = _currentWeek.add(const Duration(days: 7))),
            onGoToPreviousWeek: () => setState(() => _currentWeek = _currentWeek.subtract(const Duration(days: 7))),
            getDateForDayIndex: _getDateForDayIndex,
            onRefresh: () async => ref.refresh(weekPlansProvider((studentId: widget.student.id, weekDate: _currentWeek))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
      ),
    );
  }
}
