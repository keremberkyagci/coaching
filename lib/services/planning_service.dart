import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';
import '../models/topic_model.dart';

class PlanningService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<LessonModel>> getLessonsForExam(String examType, {String? lessonType}) async {
    try {
      Query query = _firestore
          .collection('exam_types')
          .doc(examType)
          .collection('lessons');

      if (lessonType != null && lessonType != 'Tümü') {
        query = query.where('type', isEqualTo: lessonType);
      }

      final snapshot = await query.orderBy('order').get();

      return snapshot.docs.map((doc) {
        try {
          return LessonModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          debugPrint('--- MODEL PARSE HATASI ---');
          debugPrint('Hatalı Ders Doküman ID: ${doc.id}');
          debugPrint('Hatanın Sebebi: $e');
          debugPrint('Hatalı Veri: ${doc.data()}');
          debugPrint('-------------------------');
          return null; // Hatalı veriyi atla
        }
      }).whereType<LessonModel>().toList(); // Sadece null olmayan, başarılı olanları listeye ekle

    } catch (e) {
      debugPrint('Genel Sorgu Hatası: $e');
      return [];
    }
  }

  Future<List<TopicModel>> getTopicsForLesson(
      String examType, String lessonId) async {
    try {
      final snapshot = await _firestore
          .collection('exam_types')
          .doc(examType)
          .collection('lessons')
          .doc(lessonId)
          .collection('topics')
          .orderBy('order') // YALNIZCA ORDER'A GÖRE SIRALA
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs
          .map((doc) => TopicModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting topics: $e');
      return [];
    }
  }
}
