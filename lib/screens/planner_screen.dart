import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/plan_model.dart';
import '../models/lesson_model.dart';
import '../models/topic_model.dart';
import '../providers/providers.dart';
import '../widgets/planner/planner_base_view.dart';
import '../widgets/planner/task_editor.dart';

/// Öğrencinin haftalık çalışma planını gösteren ana ekran.
/// Bu ekran hem öğrenciler hem de koçlar tarafından kullanılabilir.
class PlannerScreen extends ConsumerStatefulWidget {
  /// Planı görüntülenen öğrenci
  final UserModel student;

  const PlannerScreen({super.key, required this.student});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  /// Şu anda görüntülenen hafta
  late DateTime _currentWeek;

  /// TYT ders listesi
  List<LessonModel> _tytLessons = [];

  /// AYT ders listesi
  List<LessonModel> _aytLessons = [];

  /// Seçili sınav türü
  String? _selectedExamType;

  @override
  void initState() {
    super.initState();
    // Saati sıfırlanmış bugünün tarihi
    final now = DateTime.now();
    _currentWeek = DateTime(now.year, now.month, now.day);
    _selectedExamType = widget.student.examType;

    Future.microtask(() {
      if (_selectedExamType != null && _selectedExamType!.isNotEmpty) {
        _loadAllLessons();
      }
    });
  }

  /// Öğrencinin sınav türüne göre (YKS vb.)
  /// Firestore'dan tüm dersleri yükler
  Future<void> _loadAllLessons() async {
    if (_selectedExamType == null || _selectedExamType!.isEmpty) return;

    final allLessons = await ref
        .read(planRepositoryProvider)
        .getLessonsForExam(_selectedExamType!);

    if (mounted) {
      setState(() {
        /// Dersleri TYT ve AYT olarak ayırıyoruz
        _tytLessons = allLessons.where((l) => l.type == 'TYT').toList();
        _aytLessons = allLessons.where((l) => l.type == 'AYT').toList();
      });
    }
  }

  /// Bir ders seçildiğinde o derse ait konuları getirer
  Future<List<TopicModel>> _fetchTopicsForLesson(String lessonId) async {
    if (_selectedExamType == null || _selectedExamType!.isEmpty) return [];

    return ref
        .read(planRepositoryProvider)
        .getTopicsForLesson(_selectedExamType!, lessonId);
  }

  /// Yeni plan kaydeder
  Future<void> _savePlan(PlanModel plan) async {
    await ref.read(planRepositoryProvider).addPlan(plan);
  }

  /// Plan silme işlemi
  Future<void> _deletePlan(PlanModel plan) async {
    if (plan.id != null) {
      await ref.read(planRepositoryProvider).plansRef.doc(plan.id!).delete();
    }
  }

  /// Task editor modalını açar
  /// Yeni görev ekleme veya mevcut görevi düzenleme için kullanılır
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
          /// düzenlenecek plan
          plan: plan,

          /// haftanın hangi günü
          dayIndex: dayIndex,

          /// plan sahibi öğrenci
          student: widget.student,

          /// plan kaydetme callback
          onSavePlan: _savePlan,

          /// gün indexinden gerçek tarih üretir
          getDateForDayIndex: (index) =>
              _getDateForDayIndex(index, referenceDate: _currentWeek),

          /// planı kimin oluşturduğunu belirler
          createdBy:
              ref.read(currentUserProvider).value?.userType == UserType.coach
                  ? 'coach'
                  : 'student',

          /// ders listeleri
          tytLessons: _tytLessons,
          aytLessons: _aytLessons,

          /// konu yükleme fonksiyonu
          onFetchTopics: _fetchTopicsForLesson,
        ),
      ),
    );
  }

  /// Haftanın gün indexinden gerçek tarih hesaplar
  /// (0 = Pazartesi, 6 = Pazar)
  DateTime _getDateForDayIndex(int index, {DateTime? referenceDate}) {
    final refDate = referenceDate ?? _currentWeek;

    /// haftanın başlangıcını bul
    final startOfWeek = refDate.subtract(Duration(days: refDate.weekday - 1));

    return DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    ).add(Duration(days: index));
  }

  @override
  Widget build(BuildContext context) {
    /// o an giriş yapmış kullanıcı
    final currentUser = ref.watch(currentUserProvider).value;

    /// seçili haftaya ait planları getir
    final weekPlansAsync = ref.watch(
      weekPlansProvider(
        (studentId: widget.student.id, weekDate: _currentWeek),
      ),
    );

    final examTypesAsync = ref.watch(examTypesProvider);
    final isCoach = currentUser?.userType == UserType.coach;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.name} | Planlayıcı'),
      ),
      body: Column(
        children: [
          // Koçlar için veya sınav türü seçilmemiş öğrenciler için dropdown gösterelim
          if (isCoach ||
              _selectedExamType == null ||
              _selectedExamType!.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: examTypesAsync.when(
                data: (examTypes) {
                  return DropdownButtonFormField<String>(
                    initialValue: examTypes.contains(_selectedExamType)
                        ? _selectedExamType
                        : null,
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
              /// veri geldiğinde
              data: (plans) {
                /// haftalık planları günlere ayır
                final dailyPlans = <int, List<PlanModel>>{};

                for (final plan in plans) {
                  final dayIndex = plan.date.weekday - 1;

                  dailyPlans.putIfAbsent(dayIndex, () => []).add(plan);
                }

                /// planları oluşturulma tarihine göre sırala
                dailyPlans.forEach(
                  (key, value) =>
                      value.sort((a, b) => a.createdAt.compareTo(b.createdAt)),
                );

                return PlannerBaseView(
                  student: widget.student,

                  /// giriş yapan kişinin rolü
                  currentUserType: currentUser?.userType.name,

                  /// haftalık planlar
                  dailyPlans: dailyPlans,

                  /// loading map
                  isLoading: {for (int i = 0; i < 7; i++) i: false},

                  /// aktif hafta
                  currentWeek: _currentWeek,

                  /// görev düzenleme
                  onEditTask: (dynamic plan, int dayIndex) => _showTaskEditor(
                      plan: plan as PlanModel, dayIndex: dayIndex),

                  /// plan silme
                  onDeletePlan: _deletePlan,

                  /// yeni görev ekleme
                  onAddNewTask: (dayIndex) =>
                      _showTaskEditor(dayIndex: dayIndex),

                  /// sonraki hafta
                  onGoToNextWeek: () =>
                      setState(() => _currentWeek = _currentWeek.add(
                            const Duration(days: 7),
                          )),

                  /// önceki hafta
                  onGoToPreviousWeek: () =>
                      setState(() => _currentWeek = _currentWeek.subtract(
                            const Duration(days: 7),
                          )),

                  getDateForDayIndex: _getDateForDayIndex,

                  /// sayfayı yenile
                  onRefresh: () async => ref.refresh(
                    weekPlansProvider(
                      (studentId: widget.student.id, weekDate: _currentWeek),
                    ),
                  ),
                );
              },

              /// loading durumu
              loading: () => const Center(child: CircularProgressIndicator()),

              /// hata durumu
              error: (err, stack) => Center(child: Text('Hata: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
