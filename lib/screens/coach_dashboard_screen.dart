import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Kopyalama için eklendi
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';
import 'chat_list_screen.dart';
import 'student_detail_screen.dart';
import 'lesson_stats_detail_screen.dart'; 
import 'edit_profile_screen.dart';

class CoachDashboardScreen extends ConsumerWidget {
  const CoachDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Koç Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: userAsyncValue.when(
        data: (coachModel) {
          if (coachModel == null) {
            return const Center(child: Text("Koç verisi bulunamadı."));
          }
          return _CoachDashboardBody(coach: coachModel);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Bir hata oluştu: $err')),
      ),
    );
  }
}

class _CoachDashboardBody extends ConsumerStatefulWidget {
  final UserModel coach;
  const _CoachDashboardBody({required this.coach});

  @override
  ConsumerState<_CoachDashboardBody> createState() => _CoachDashboardBodyState();
}

class _CoachDashboardBodyState extends ConsumerState<_CoachDashboardBody> {
  int _selectedIndex = 0; 

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      _StudentListTab(coach: widget.coach),
      const ChatListScreen(),
      _CoachProfileTab(coach: widget.coach),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'Öğrenciler'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Mesajlar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}


class _StudentListTab extends ConsumerWidget {
  final UserModel coach;
  const _StudentListTab({required this.coach});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsyncValue = ref.watch(studentsForCoachProvider(coach.id));

    return studentsAsyncValue.when(
      data: (students) {
        if (students.isEmpty) {
          return const Center(child: Text('Henüz bağlı öğrenciniz yok.'));
        }
        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: student.profileImageUrl != null
                          ? NetworkImage(student.profileImageUrl!)
                          : null,
                      child: student.profileImageUrl == null
                          ? Text(student.name.isNotEmpty ? student.name[0] : '?')
                          : null,
                    ),
                    title: Text(student.name),
                    subtitle: Text(student.email),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudentDetailScreen(student: student),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _StudentStats(student: student),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Öğrenciler yüklenemedi: $err')),
    );
  }
}

class _StudentStats extends ConsumerWidget {
  final UserModel student;
  const _StudentStats({required this.student});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsyncValue = ref.watch(studentStatsProvider(student.id));

    return statsAsyncValue.when(
      data: (statsList) {
        if (statsList.isEmpty) {
          return const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'İstatistik yok',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: statsList.map((stats) {
            final correct = stats.totalCorrect;
            final incorrect = stats.totalIncorrect;
            final total = correct + incorrect;
            final successRate = total == 0 ? 0.0 : (correct / total) * 100;

            return InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LessonStatsDetailScreen(
                      studentId: student.id,
                      lessonName: stats.lessonName,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  '${stats.lessonName}: %${successRate.toStringAsFixed(0)} Başarı',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      decoration: TextDecoration.underline),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox(height: 20, child: Center(child: LinearProgressIndicator())),
      error: (err, stack) => const Text('İstatistik yüklenemedi.', style: TextStyle(fontSize: 12, color: Colors.red)),
    );
  }
}

class _CoachProfileTab extends StatelessWidget {
  final UserModel coach;
  const _CoachProfileTab({required this.coach});

  Widget _buildDetailRow(BuildContext context, String title, String? value, {bool isCopiable = false}) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: SelectableText(value)),
          if (isCopiable)
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kopyalandı!')),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: coach.profileImageUrl != null && coach.profileImageUrl!.isNotEmpty
                  ? NetworkImage(coach.profileImageUrl!)
                  : null,
              child: coach.profileImageUrl == null || coach.profileImageUrl!.isEmpty
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              coach.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SelectableText(
              coach.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow(context, 'Kullanıcı ID', coach.id, isCopiable: true),
            _buildDetailRow(context, 'Deneyim', '${coach.yearsOfCoaching ?? 0} yıl'),
             if(coach.biography != null && coach.biography!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Hakkında', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  coach.biography!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Profili Düzenle'),
                onPressed: () {
                   Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => EditProfileScreen(user: coach)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
