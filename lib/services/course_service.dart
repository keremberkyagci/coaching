// ============================================================
// lib/services/course_service.dart — Ders ekleme yardımcı servisi
//
// Firestore'daki 'courses' koleksiyonuna ders eklemek için kullanılır.
// addInitialCourses(): Verilen ders isimlerini tek tek kontrol eder;
//   eğer o isimde ders yoksa ekler, varsa atlar.
//
// NOT: Bu servis şu an aktif UI akışında kullanılmıyor gibi görünüyor.
//      Başlangıç verisini seed etmek için kullanılmış olabilir.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class CourseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addInitialCourses(List<String> courseNames) async {
    final CollectionReference coursesCollection = _firestore.collection('courses');

    for (String courseName in courseNames) {
      // Dersin zaten var olup olmadığını kontrol et
      final QuerySnapshot snapshot = await coursesCollection.where('name', isEqualTo: courseName).get();

      if (snapshot.docs.isEmpty) {
        // Ders yoksa ekle
        await coursesCollection.add({
          'name': courseName,
          'createdAt': FieldValue.serverTimestamp(),
        });
        developer.log('Ders eklendi: $courseName', name: 'CourseService');
      } else {
        developer.log('Ders zaten mevcut: $courseName', name: 'CourseService');
      }
    }
  }
}