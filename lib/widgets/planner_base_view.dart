import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/plan_model.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';
import '../services/authorization_service.dart';
import '../utils/constants.dart';

class PlannerBaseView extends ConsumerStatefulWidget {
  final UserModel student;
  final String? currentUserType;
  final Map<int, List<PlanModel>> dailyPlans;
  final Map<int, bool> isLoading;
  final DateTime currentWeek;
  final void Function(PlanModel plan, int dayIndex) onEditTask;
  final void Function(PlanModel plan) onDeletePlan;
  final void Function(int dayIndex) onAddNewTask;
  final VoidCallback onGoToNextWeek;
  final VoidCallback onGoToPreviousWeek;
  final Future<void> Function()? onMarkPlansAsSeen;
  final DateTime Function(int, {DateTime? referenceDate}) getDateForDayIndex;
  final Future<void> Function() onRefresh;

  const PlannerBaseView({
    super.key,
    required this.student,
    required this.currentUserType,
    required this.dailyPlans,
    required this.isLoading,
    required this.currentWeek,
    required this.onEditTask,
    required this.onDeletePlan,
    required this.onAddNewTask,
    required this.onGoToNextWeek,
    required this.onGoToPreviousWeek,
    this.onMarkPlansAsSeen,
    required this.getDateForDayIndex,
    required this.onRefresh,
  });

  @override
  ConsumerState<PlannerBaseView> createState() => _PlannerBaseViewState();
}

class _PlannerBaseViewState extends ConsumerState<PlannerBaseView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<int, ScrollController> _scrollControllers = {};
  final Map<int, Map<String, bool>> _sectionExpandedState = {};

  @override
  void initState() {
    super.initState();
    int initialIndex = DateTime.now().weekday - 1;
    _tabController = TabController(length: 7, vsync: this, initialIndex: initialIndex);

    for (int i = 0; i < 7; i++) {
      _scrollControllers[i] = ScrollController();
      _sectionExpandedState.putIfAbsent(i, () => {'coach': true, 'student': true});
    }

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        final currentDayIndex = _tabController.index;
        _sectionExpandedState.putIfAbsent(currentDayIndex, () => {'coach': true, 'student': true});
        setState(() {});
        widget.onMarkPlansAsSeen?.call();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getWeekDateRange(DateTime date) {
    final startOfWeek = widget.getDateForDayIndex(0, referenceDate: date);
    final endOfWeek = widget.getDateForDayIndex(6, referenceDate: date);
    final DateFormat formatter = DateFormat('d MMMM y', 'tr_TR');
    return '${formatter.format(startOfWeek)} - ${formatter.format(endOfWeek)}';
  }

  void _toggleSectionExpanded(int dayIndex, String sectionType) {
    setState(() {
      final bool currentState = _sectionExpandedState[dayIndex]?[sectionType] ?? true;
      _sectionExpandedState[dayIndex]![sectionType] = !currentState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: widget.onGoToPreviousWeek),
              Text(
                _getWeekDateRange(widget.currentWeek),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: widget.onGoToNextWeek),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: List.generate(7, (index) {
            final dayDate = widget.getDateForDayIndex(index);
            final dayName = daysOfWeek[index];
            final dateText = DateFormat('dd/MM').format(dayDate);
            return Tab(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text(dateText, style: const TextStyle(fontSize: 10)), const SizedBox(height: 4), Text(dayName)],
            ));
          }),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: TabBarView(
              controller: _tabController,
              children: List.generate(7, (dayIndex) {
                return _buildDayView(dayIndex);
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayView(int dayIndex) {
    if (widget.isLoading[dayIndex] ?? true) {
      return const Center(child: CircularProgressIndicator());
    }
    final allPlans = widget.dailyPlans[dayIndex] ?? [];
    final studentPlans = allPlans.where((p) => p.createdBy == 'student').toList();
    final coachPlans = allPlans.where((p) => p.createdBy == 'coach').toList();
    final isCoachSectionExpanded = _sectionExpandedState[dayIndex]?['coach'] ?? true;
    final isStudentSectionExpanded = _sectionExpandedState[dayIndex]?['student'] ?? true;
    
    return ListView(
      controller: _scrollControllers[dayIndex],
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildPlanSection(
          'Koçun Planı',
          coachPlans,
          editable: widget.currentUserType == 'coach',
          dayIndex: dayIndex,
          sectionType: 'coach',
          isExpanded: isCoachSectionExpanded,
          onToggleExpanded: _toggleSectionExpanded,
        ),
        const SizedBox(height: 24),
        _buildPlanSection(
          'Benim Planım',
          studentPlans,
          editable: widget.currentUserType == 'student',
          dayIndex: dayIndex,
          sectionType: 'student',
          isExpanded: isStudentSectionExpanded,
          onToggleExpanded: _toggleSectionExpanded,
        ),
      ],
    );
  }

  Widget _buildPlanSection(
    String title,
    List<PlanModel> plans, {
    required bool editable,
    required int dayIndex,
    required String sectionType,
    required bool isExpanded,
    required Function(int, String) onToggleExpanded,
  }) {
    final authService = ref.watch(authorizationServiceProvider);
    final canCreatePlan = authService.canAccessFeature(Feature.createPlan, widget.student);
    
    final tytPlans = plans.where((p) => p.lessonType == 'TYT').toList();
    final aytPlans = plans.where((p) => p.lessonType == 'AYT').toList();
    final otherPlans = plans.where((p) => p.lessonType != 'TYT' && p.lessonType != 'AYT').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (editable && canCreatePlan)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
                    onPressed: () => widget.onAddNewTask(dayIndex),
                  ),
                IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => onToggleExpanded(dayIndex, sectionType),
                ),
              ],
            ),
          ],
        ),
        const Divider(),
        if (isExpanded)
          if (plans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                  child: Text(
                      editable
                          ? 'Plan eklemek için + ikonuna dokunun.'
                          : 'Bu gün için plan bulunmuyor.',
                      style: const TextStyle(color: Colors.grey))),
            )
          else ...[
            ...otherPlans.map((plan) => _buildPlanCard(plan, editable, dayIndex)),
            if (tytPlans.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(top: 16.0, bottom: 4.0, left: 4.0),
                child: Text('TYT Çalışmaları',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                        fontSize: 16)),
              ),
              ...tytPlans.map((plan) => _buildPlanCard(plan, editable, dayIndex)),
            ],
            if (aytPlans.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(top: 16.0, bottom: 4.0, left: 4.0),
                child: Text('AYT Çalışmaları',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                        fontSize: 16)),
              ),
              ...aytPlans.map((plan) => _buildPlanCard(plan, editable, dayIndex)),
            ],
          ]
      ],
    );
  }

  // DÜZELTME: Veri tutarsızlıklarına karşı en güvenli hale getirildi.
  Widget _buildPlanCard(PlanModel plan, bool editable, int dayIndex) {
    String titleText = plan.lessonName;
    String subtitleText = 'Hatalı veri'; // Varsayılan hata mesajı
    final details = plan.details;

    switch (plan.activityType) {
      case ActivityType.study:
        if (details is StudyDetails) { // Önce türü kontrol et
          subtitleText = '${plan.topicName} - ${details.durationMinutes} dk';
        }
        break;
      case ActivityType.test:
        if (details is TestDetails) { // Önce türü kontrol et
          final count = details.plannedQuestionCount ?? details.actualQuestionCount;
          subtitleText = '${plan.topicName} - $count soru';
        }
        break;
      case ActivityType.branchTrial:
        if (details is TestDetails) { // Önce türü kontrol et
          final count = details.plannedQuestionCount ?? details.actualQuestionCount;
          titleText = plan.lessonName;
          subtitleText = 'Branş Denemesi - $count soru';
        }
        break;
      case ActivityType.breakTime:
        subtitleText = 'Mola';
        break;
      case ActivityType.other:
        subtitleText = 'Diğer';
        break;
    }

    return Card(
      key: ValueKey(plan.id),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(titleText),
        subtitle: Text(subtitleText),
        trailing: editable
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () => widget.onEditTask(plan, dayIndex),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => widget.onDeletePlan(plan),
                  ),
                ],
              )
            : _getStatusIcon(plan.isCompleted),
      ),
    );
  }

  Icon _getStatusIcon(bool isCompleted) {
    if (isCompleted) {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else {
      return const Icon(Icons.hourglass_top, color: Colors.blue);
    }
  }
}
