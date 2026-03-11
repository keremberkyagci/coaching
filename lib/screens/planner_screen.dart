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
  
  String? _selectedExamType;

  @override
  void initState() {
    super.initState();
    _currentWeek = DateTime.now();
    _selectedExamType = widget.student.examType;
    
    Future.microtask(() {
      if (_selectedExamType != null && _selectedExamType!.isNotEmpty) {
        _loadAllLessons();
      }
    });
  }

  Future<void> _loadAllLessons() async {
    if (_selectedExamType == null || _selectedExamType!.isEmpty) return;

    final allLessons = await ref.read(planRepositoryProvider).getLessonsForExam(_selectedExamType!);
    if (mounted) {
      setState(() {
        _tytLessons = allLessons.where((l) => l.type == 'TYT').toList();
        _aytLessons = allLessons.where((l) => l.type == 'AYT').toList();
      });
    }
  }

  Future<List<TopicModel>> _fetchTopicsForLesson(String lessonId) async {
    if (_selectedExamType == null || _selectedExamType!.isEmpty) return [];
    return ref.read(planRepositoryProvider).getTopicsForLesson(_selectedExamType!, lessonId);
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
    if (_selectedExamType == null || _selectedExamType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce bir sınav türü seçin.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        child: TaskEditor(
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
    final examTypesAsync = ref.watch(examTypesProvider);
    final isCoach = currentUser?.userType == UserType.coach;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.name} | Planlayıcı'),
      ),
      body: Column(
        children: [
          // Koçlar için veya sınav türü seçilmemiş öğrenciler için dropdown gösterelim
          if (isCoach || _selectedExamType == null || _selectedExamType!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: examTypesAsync.when(
                data: (examTypes) {
                  return DropdownButtonFormField<String>(
                    value: examTypes.contains(_selectedExamType) ? _selectedExamType : null,
                    hint: const Text('Sınav Türü Seçin'),
                    decoration: const InputDecoration(
                      labelText: 'Sınav Türü',
                      border: OutlineInputBorder(),
                    ),
                    items: examTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null && newValue != _selectedExamType) {
                        setState(() {
                          _selectedExamType = newValue;
                          _tytLessons = [];
                          _aytLessons = [];
                        });
                        _loadAllLessons();
                      }
                    },
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (err, stack) => const Text('Sınav türleri yüklenemedi.'),
              ),
            ),
            
          Expanded(
            child: weekPlansAsync.when(
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
          ),
        ],
      ),
    );
  }
}
