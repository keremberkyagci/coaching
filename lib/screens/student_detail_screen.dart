// lib/screens/student_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';

// DÜZELTME: StatefulWidget -> ConsumerWidget ve constructor güncellendi.
class StudentDetailScreen extends ConsumerWidget {
  final UserModel student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Koç bilgisini almak için yeni bir provider oluşturabilir veya doğrudan Firestore'u kullanabiliriz.
    // Şimdilik basitlik adına doğrudan bir FutureProvider kullanalım.
    final coachProvider = FutureProvider.autoDispose<UserModel?>((provRef) async {
      final coachId = student.coachConnection?['coachId'];
      if (coachId != null) {
        return await provRef.watch(userRepositoryProvider).getUserById(coachId);
      }
      return null;
    });

    final coachAsyncValue = ref.watch(coachProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(student.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [

                    Expanded(
                      child: Text(
                        student.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoCard('Öğrenim Gördüğü Lise', student.highSchool ?? 'Belirtilmemiş'),
            // Koç bilgisini asenkron olarak göster
            coachAsyncValue.when(
              data: (coach) => _buildInfoCard('Bağlı Olduğu Koç', coach?.name ?? 'Koç atanmamış'),
              loading: () => const Card(child: ListTile(title: Text('Bağlı Olduğu Koç'), subtitle: LinearProgressIndicator())),
              error: (err, st) => _buildInfoCard('Bağlı Olduğu Koç', 'Bilgi alınamadı'),
            ),
            _buildInfoCard('İstediği Bölüm', student.targetMajor ?? 'Belirtilmemiş'),
            _buildInfoCard('İstediği Sıralama', student.targetRank ?? 'Belirtilmemiş'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ),
    );
  }
}
