// lib/screens/student_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';
import 'planner_screen.dart'; // YENİ: Öğrenci planlayıcısı için import

class StudentDetailScreen extends ConsumerWidget {
  final UserModel student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Koç ID'sini belirle
    final String? coachId = student.coachId ?? student.coachConnection?['coachId'];

    // Eğer koç ID'si geçerliyse, önceden tanımlı provider üzerinden koçu çek
    // (Böylece build metodu her çalıştığında FutureProvider yeniden üretilmez ve sonsuz döngü/sürekli loading olmaz)
    final AsyncValue<UserModel?> coachAsyncValue =
        (coachId != null && coachId.isNotEmpty)
            ? ref.watch(assignedCoachProvider(coachId))
            : const AsyncValue.data(null);

    // Mevcut kullanıcı (Koç mu öğrenci mi kontrolü için)
    final currentUser = ref.watch(currentUserProvider).value;

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
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: student.profileImageUrl != null
                          ? NetworkImage(student.profileImageUrl!)
                          : null,
                      child: student.profileImageUrl == null
                          ? const Icon(Icons.person_outline, size: 50)
                          : null,
                    ),
                    const SizedBox(width: 20),
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
            
            // Koç ise Programa Git butonu
            if (currentUser?.userType == UserType.coach) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PlannerScreen(student: student),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Öğrencinin Programına Git (Planla)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            _buildInfoCard('Öğrenim Gördüğü Lise', student.highSchool ?? 'Belirtilmemiş'),
            // Koç bilgisini asenkron olarak göster
            coachAsyncValue.when(
              data: (coach) => _buildInfoCard('Bağlı Olduğu Koç', coach?.name ?? 'Koç atanmamış'),
              loading: () => const Card(
                child: ListTile(
                  title: Text('Bağlı Olduğu Koç'),
                  subtitle: LinearProgressIndicator(),
                ),
              ),
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
