import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:focus_app_v2_final/models/lesson_model.dart';
import 'package:focus_app_v2_final/models/plan_model.dart';
import 'package:focus_app_v2_final/models/topic_model.dart';
import 'package:focus_app_v2_final/models/user_model.dart';
import 'package:focus_app_v2_final/providers/providers.dart';
import 'package:collection/collection.dart';

class AddTaskDialog extends ConsumerStatefulWidget {
  final String assignedToId;
  final String examType;

  const AddTaskDialog({
    super.key,
    required this.assignedToId,
    required this.examType,
  });

  @override
  ConsumerState<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends ConsumerState<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  LessonModel? _selectedLesson;
  TopicModel? _selectedTopic;
  DateTime? _selectedDueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTask(UserModel? currentUser) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); 
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Hata: Oturum açmış kullanıcı bulunamadı.')),
        );
        return;
      }

      // DÜZELTME: TaskModel yerine PlanModel oluşturuluyor.
      final newPlan = PlanModel(
        studentId: widget.assignedToId,
        date: _selectedDueDate ?? DateTime.now(),
        lessonName: _selectedLesson?.name ?? _titleController.text,
        lessonType: _selectedLesson?.type,
        topicName: _selectedTopic?.name ?? _descriptionController.text,
        activityType: ActivityType.other, // Genel bir görev türü olarak
        details: StudyDetails(durationMinutes: 0), // Boş detay
        isCompleted: false,
        createdBy: currentUser.id,
        createdAt: Timestamp.now(),
        lessonId: _selectedLesson?.id ?? '',
      );

      // DÜZELTME: addTask yerine addPlan kullanılıyor.
      ref.read(planRepositoryProvider).addPlan(newPlan);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsyncValue = ref.watch(lessonsForUserProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return AlertDialog(
      title: const Text('Yeni Görev Ekle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Görev Başlığı'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Başlık boş olamaz.' : null,
              ),
              const SizedBox(height: 16),
              lessonsAsyncValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Hata: Dersler yüklenemedi',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
                data: (lessons) {
                  if (lessons.isEmpty) {
                    return const Text('Uygun ders bulunamadı.',
                        style: TextStyle(color: Colors.grey));
                  }
                  return FormField<LessonModel>(
                    initialValue: _selectedLesson,
                    onSaved: (newValue) => _selectedLesson = newValue,
                    validator: (value) => value == null ? 'Lütfen bir ders seçin.' : null,
                    builder: (state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButton<LessonModel>(
                            value: state.value,
                            hint: const Text("Ders Seçin"),
                            isExpanded: true,
                            items: lessons
                                .map((lesson) =>
                                    DropdownMenuItem(value: lesson, child: Text(lesson.name)))
                                .toList(),
                            onChanged: (value) {
                              state.didChange(value);
                              setState(() {
                                _selectedLesson = value;
                                _selectedTopic = null;
                              });
                            },
                          ),
                          if (state.hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                            )
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_selectedLesson != null)
                Consumer(
                  builder: (context, ref, child) {
                    final lessonId = _selectedLesson!.id;
                    if (lessonId == null) {
                      return const Text('Dersin kimliği bulunamadı.');
                    }
                    final topicsAsyncValue = ref.watch(topicsForLessonProvider(
                      (examId: widget.examType, lessonId: lessonId),
                    ));

                    return topicsAsyncValue.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => const Text('Konular yüklenemedi.'),
                      data: (topics) {
                        return FormField<TopicModel>(
                          initialValue: _selectedTopic,
                          onSaved: (newValue) => _selectedTopic = newValue,
                          validator: (value) => value == null ? 'Lütfen bir konu seçin.' : null,
                          builder: (state) {
                             final selectedValue = state.value == null ? null : topics.firstWhereOrNull((t) => t.id == state.value!.id);
                             return Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 DropdownButton<TopicModel>(
                                   value: selectedValue,
                                   hint: const Text("Konu Seçin"),
                                   isExpanded: true,
                                   items: _buildTopicsDropdownItems(topics),
                                   onChanged: (value) {
                                     state.didChange(value);
                                     setState(() => _selectedTopic = value);
                                   },
                                 ),
                                 if(state.hasError)
                                   Padding(
                                     padding: const EdgeInsets.only(top: 5.0),
                                     child: Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                                   )
                               ],
                             );
                          },
                        );
                      },
                    );
                  },
                )
              else
                const SizedBox.shrink(),
              const SizedBox(height: 20),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(_selectedDueDate == null
                    ? 'Son Teslim Tarihi Seç'
                    : DateFormat.yMd('tr_TR').format(_selectedDueDate!)),
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() => _selectedDueDate = pickedDate);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('İptal'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('Ekle'),
          onPressed: () => _saveTask(currentUser),
        ),
      ],
    );
  }

  List<DropdownMenuItem<TopicModel>> _buildTopicsDropdownItems(
      List<TopicModel> topics) {
    final List<DropdownMenuItem<TopicModel>> items = [];
    String? currentGroup;

    for (final topic in topics) {
      if (topic.group != currentGroup) {
        currentGroup = topic.group;
        final headerText = currentGroup == null ? "Genel Konular" : "--- $currentGroup ---";
        items.add(
          DropdownMenuItem(
            enabled: false,
            child: Text(headerText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        );
      }
      
      final prefix = topic.group != null ? "  • " : "";
      items.add(
        DropdownMenuItem(
          value: topic,
          child: Text("$prefix${topic.name}"),
        ),
      );
    }
    
    return items;
  }
}
