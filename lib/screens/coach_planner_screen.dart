import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app_v2_final/providers/providers.dart';
import '../models/user_model.dart';
import '../models/plan_model.dart';
import '../models/lesson_model.dart';
import '../models/topic_model.dart';
import '../widgets/planner_base_view.dart';
import '../widgets/task_editor.dart';
import 'dart:async';

class CoachPlannerScreen extends ConsumerStatefulWidget {
  final UserModel student;

  const CoachPlannerScreen({super.key, required this.student});

  @override
  ConsumerState<CoachPlannerScreen> createState() => CoachPlannerScreenState();
}

class CoachPlannerScreenState extends ConsumerState<CoachPlannerScreen> {
  late DateTime _currentWeek;
  Stream<List<PlanModel>>? _plansStream;

  List<LessonModel> _tytLessons = [];
  List<LessonModel> _aytLessons = [];
  
  // YENİ: Seçili sınav türünü tutmak için state
  String? _selectedExamType;

  @override
  void initState() {
    super.initState();
    _currentWeek = DateTime.now();
    // YENİ: Öğrencinin mevcut sınav türüyle başlat
    _selectedExamType = widget.student.examType;
    
    Future.microtask(() {
      _setupPlansStream();
      // YENİ: Sadece bir sınav türü seçiliyse dersleri yükle
      if (_selectedExamType != null) {
        _loadAllLessons();
      }
    });
  }
  
  Future<void> _loadAllLessons() async {
    // YENİ: State'ten gelen seçili sınav türünü kullan
    if (_selectedExamType == null || _selectedExamType!.isEmpty) return;

    final planRepository = ref.read(planRepositoryProvider);
    final allLessons = await planRepository.getLessonsForExam(_selectedExamType!);
    
    if (mounted) {
      setState(() {
        _tytLessons = allLessons.where((lesson) => lesson.type == 'TYT').toList();
        _aytLessons = allLessons.where((lesson) => lesson.type == 'AYT').toList();
      });
    }
  }

  Future<List<TopicModel>> _fetchTopicsForLesson(String lessonId) async {
    // YENİ: State'ten gelen seçili sınav türünü kullan
    if (_selectedExamType == null || _selectedExamType!.isEmpty) return [];
    
    return await ref.read(planRepositoryProvider).getTopicsForLesson(_selectedExamType!, lessonId);
  }

  void _setupPlansStream() {
    final now = _currentWeek;
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    _plansStream = ref.read(planRepositoryProvider).getPlansForStudent(
        widget.student.id, startOfWeek, endOfWeek);
    setState(() {});
  }
  
  DateTime _getDateForDayIndex(int index, {DateTime? referenceDate}) {
    final refDate = referenceDate ?? _currentWeek;
    final startOfWeek = refDate.subtract(Duration(days: refDate.weekday - 1));
    return DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)
        .add(Duration(days: index));
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

  Future<void> _savePlan(PlanModel plan) async {
    final planRepository = ref.read(planRepositoryProvider);
    await planRepository.addPlan(plan);
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
          createdBy: 'coach',
          tytLessons: _tytLessons,
          aytLessons: _aytLessons,
          onFetchTopics: _fetchTopicsForLesson,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // YENİ: Sınav türleri listesi (burası bir servisten de gelebilir)
    const examTypes = ['YKS', 'LGS', 'KPSS'];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.name} | Planlayıcı'),
      ),
      body: Column(
        children: [
          // YENİ: Sınav Türü Seçimi Dropdown'ı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedExamType,
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
                    // Yeni seçim yapıldığında ders listelerini temizle ve yeniden yükle
                    _tytLessons = [];
                    _aytLessons = [];
                    _loadAllLessons();
                  });
                }
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PlanModel>>(
              stream: _plansStream,
              builder: (context, snapshot) {
                final dailyPlans = <int, List<PlanModel>>{};
                if (snapshot.hasData) {
                  final allPlans = snapshot.data ?? [];
                  for (final plan in allPlans) {
                    final dayIndex = plan.date.weekday - 1;
                    dailyPlans.putIfAbsent(dayIndex, () => []).add(plan);
                  }
                  dailyPlans.forEach((key, value) {
                    value.sort((a, b) => (a.createdAt).compareTo(b.createdAt));
                  });
                }

                return PlannerBaseView(
                  student: widget.student,
                  currentUserType: 'coach',
                  dailyPlans: dailyPlans,
                  isLoading: { for (var i = 0; i < 7; i++) i: snapshot.connectionState == ConnectionState.waiting },
                  currentWeek: _currentWeek,
                  onEditTask: (plan, dayIndex) =>
                      _showTaskEditor(plan: plan, dayIndex: dayIndex),
                  onDeletePlan: _deletePlan,
                  onAddNewTask: (dayIndex) => _showTaskEditor(dayIndex: dayIndex),
                  onGoToPreviousWeek: _goToPreviousWeek,
                  onGoToNextWeek: _goToNextWeek,
                  getDateForDayIndex: (index, {referenceDate}) => _getDateForDayIndex(
                      index,
                      referenceDate: referenceDate ?? _currentWeek),
                  onRefresh: () async => _setupPlansStream(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
