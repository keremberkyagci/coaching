import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String? id; // GÜNCELLENDİ: ID tekrar nullable yapıldı.
  final String title;
  final String description;
  final Timestamp? dueDate;
  final bool isCompleted;
  final String createdBy;
  final String assignedTo;
  final Timestamp createdAt;
  final String? lessonId;
  final String? lessonName;
  final String? topicName;

  TaskModel({
    this.id, // GÜNCELLENDİ: ID artık zorunlu değil.
    required this.title,
    this.description = '',
    this.dueDate,
    this.isCompleted = false,
    required this.createdBy,
    required this.assignedTo,
    required this.createdAt,
    this.lessonId,
    this.lessonName,
    this.topicName,
  });

  factory TaskModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return TaskModel(
      id: snapshot.id,
      title: data?['title'] ?? '',
      description: data?['description'] ?? '',
      dueDate: data?['dueDate'] as Timestamp?,
      isCompleted: data?['isCompleted'] ?? false,
      createdBy: data?['createdBy'] ?? '',
      assignedTo: data?['assignedTo'] ?? '',
      createdAt: data?['createdAt'] ?? Timestamp.now(),
      lessonId: data?['lessonId'] as String?,
      lessonName: data?['lessonName'] as String?,
      topicName: data?['topicName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      if (dueDate != null) 'dueDate': dueDate,
      'isCompleted': isCompleted,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'createdAt': createdAt,
      if (lessonId != null) 'lessonId': lessonId,
      if (lessonName != null) 'lessonName': lessonName,
      if (topicName != null) 'topicName': topicName,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    Timestamp? dueDate,
    bool? isCompleted,
    String? createdBy,
    String? assignedTo,
    Timestamp? createdAt,
    String? lessonId,
    String? lessonName,
    String? topicName,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      lessonId: lessonId ?? this.lessonId,
      lessonName: lessonName ?? this.lessonName,
      topicName: topicName ?? this.topicName,
    );
  }
}
