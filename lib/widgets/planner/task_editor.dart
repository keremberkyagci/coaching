import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:focus_app_v2_final/models/lesson_model.dart';
import 'package:focus_app_v2_final/models/plan_model.dart';
import 'package:focus_app_v2_final/models/topic_model.dart';
import 'package:focus_app_v2_final/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskEditor extends ConsumerStatefulWidget {
  final PlanModel? plan;
  final int dayIndex;
  final UserModel student;
  final Future<void> Function(PlanModel) onSavePlan;
  final DateTime Function(int) getDateForDayIndex;
  final String createdBy;
  final List<LessonModel> tytLessons;
  final List<LessonModel> aytLessons;
  final Future<List<TopicModel>> Function(String) onFetchTopics;

  const TaskEditor({
    super.key,
    this.plan,
    required this.dayIndex,
    required this.student,
    required this.onSavePlan,
    required this.getDateForDayIndex,
    required this.createdBy,
    required this.tytLessons,
    required this.aytLessons,
    required this.onFetchTopics,
  });

  @override
  ConsumerState<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends ConsumerState<TaskEditor> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _questionCountController;
  late TextEditingController _studyDurationController;

  String? _selectedExamType; 
  ActivityType? _activityType;
  String? _selectedLessonId;
  TopicModel? _selectedTopic;
  
  List<TopicModel> _topics = [];
  bool _isLoadingTopics = false;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    final details = plan?.details;

    _questionCountController = TextEditingController(text: details is TestDetails ? details.plannedQuestionCount?.toString() : '');
    _studyDurationController = TextEditingController(text: details is StudyDetails ? details.durationMinutes.toString() : '');

    if (plan != null) {
      _activityType = plan.activityType;
      _selectedExamType = plan.lessonType;
      _selectedLessonId = plan.lessonId;
      
      if (_selectedLessonId != null && _activityType != ActivityType.branchTrial) {
        _loadTopicsForLesson(_selectedLessonId!);
      }
    }
  }

  Future<void> _loadTopicsForLesson(String lessonId) async {
    setState(() => _isLoadingTopics = true);
    final topics = await widget.onFetchTopics(lessonId);
    if (mounted) {
      setState(() {
        _topics = topics;
        if (widget.plan?.topicName != null) {
          _selectedTopic = topics.firstWhereOrNull((t) => t.name == widget.plan!.topicName);
        }
        _isLoadingTopics = false;
      });
    }
  }

  @override
  void dispose() {
    _questionCountController.dispose();
    _studyDurationController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final selectedDate = widget.getDateForDayIndex(widget.dayIndex);
      final lesson = [...widget.tytLessons, ...widget.aytLessons].firstWhereOrNull((l) => l.id == _selectedLessonId);

      PlanDetails details;
      if (_activityType == ActivityType.study) {
        details = StudyDetails(durationMinutes: int.tryParse(_studyDurationController.text) ?? 0);
      } else { // test ve branchTrial için aynı details yapısı
        details = TestDetails(plannedQuestionCount: int.tryParse(_questionCountController.text));
      }

      final newPlan = PlanModel(
        id: widget.plan?.id,
        studentId: widget.student.id,
        date: selectedDate,
        activityType: _activityType!,
        lessonId: _selectedLessonId ?? '',
        lessonName: lesson?.name ?? '',
        lessonType: _selectedExamType,
        topicName: _activityType == ActivityType.branchTrial ? 'Branş Denemesi' : (_selectedTopic?.name ?? 'Genel'),
        details: details,
        isCompleted: false, 
        createdBy: widget.createdBy,
        createdAt: widget.plan?.createdAt ?? Timestamp.now(),
      );

      widget.onSavePlan(newPlan);
      Navigator.of(context).pop();
    }
  }

  List<DropdownMenuItem<TopicModel>> _buildTopicsDropdownItems(List<TopicModel> topics) {
    final List<DropdownMenuItem<TopicModel>> items = [];
    String? currentGroup;

    for (final topic in topics) {
      if (topic.group != currentGroup) {
        currentGroup = topic.group;
        final headerText = currentGroup == null ? "Genel Konular" : "--- $currentGroup ---";
        items.add(DropdownMenuItem(enabled: false, child: Text(headerText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))));
      }
      
      final prefix = topic.group != null ? "  • " : "";
      items.add(DropdownMenuItem(value: topic, child: Text("$prefix${topic.name}")));
    }
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final relevantLessons = _selectedExamType == 'TYT' 
        ? widget.tytLessons 
        : _selectedExamType == 'AYT' 
            ? widget.aytLessons 
            : <LessonModel>[];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.plan == null ? 'Yeni Görev Ekle' : 'Görevi Düzenle',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'TYT', label: Text('TYT')),
                ButtonSegment(value: 'AYT', label: Text('AYT')),
              ],
              selected: _selectedExamType == null ? <String>{} : {_selectedExamType!},
              emptySelectionAllowed: true,
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedExamType = newSelection.isNotEmpty ? newSelection.first : null;
                  _activityType = null; _selectedLessonId = null; _selectedTopic = null;
                });
              },
            ),
            const SizedBox(height: 16),

            if (_selectedExamType != null)
              SegmentedButton<ActivityType>(
                segments: const [
                  ButtonSegment(value: ActivityType.study, label: Text('Konu')),
                  ButtonSegment(value: ActivityType.test, label: Text('Test')),
                  ButtonSegment(value: ActivityType.branchTrial, label: Text('Branş Denemesi')),
                ],
                selected: _activityType == null ? <ActivityType>{} : {_activityType!},
                emptySelectionAllowed: true,
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _activityType = newSelection.isNotEmpty ? newSelection.first : null;
                    _selectedLessonId = null; _selectedTopic = null;
                  });
                },
              ),
            const SizedBox(height: 16),
            
            // DERS SEÇİMİ (Test, Konu ve Branş Denemesi için ortak)
            if ([ActivityType.study, ActivityType.test, ActivityType.branchTrial].contains(_activityType)) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedLessonId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Ders'),
                items: relevantLessons.map((lesson) => DropdownMenuItem(value: lesson.id, child: Text(lesson.name))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLessonId = value; _selectedTopic = null; _topics = [];
                    });
                    if (_activityType != ActivityType.branchTrial) {
                      _loadTopicsForLesson(value);
                    }
                  }
                },
                validator: (value) => value == null ? 'Lütfen bir ders seçin.' : null,
              ),
              const SizedBox(height: 16),
            ],

            // KONU SEÇİMİ (Sadece Test ve Konu için)
            if ([ActivityType.study, ActivityType.test].contains(_activityType)) ...[
              if (_isLoadingTopics)
                const Center(child: CircularProgressIndicator())
              else if (_selectedLessonId != null && _topics.isNotEmpty)
                DropdownButtonFormField<TopicModel>(
                  initialValue: _selectedTopic,
                  decoration: const InputDecoration(labelText: 'Konu'),
                  items: _buildTopicsDropdownItems(_topics),
                  onChanged: (value) => setState(() => _selectedTopic = value),
                  validator: (value) => value == null ? 'Lütfen bir konu seçin.' : null,
                ),
            ],

            // DETAY GİRİŞİ (Süre veya Soru Adedi)
            if (_activityType == ActivityType.study)
              TextFormField(
                controller: _studyDurationController,
                decoration: const InputDecoration(labelText: 'Çalışma Süresi (dk)'),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty || int.tryParse(value) == null) ? 'Geçerli bir süre girin.' : null,
              )
            else if ([ActivityType.test, ActivityType.branchTrial].contains(_activityType))
              TextFormField(
                controller: _questionCountController,
                decoration: const InputDecoration(labelText: 'Soru Adedi'),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty || int.tryParse(value) == null) ? 'Geçerli bir sayı girin.' : null,
              ),
            
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
                const SizedBox(width: 8),
                TextButton(onPressed: _saveForm, child: const Text('Kaydet')),
              ],
            ),
             const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
