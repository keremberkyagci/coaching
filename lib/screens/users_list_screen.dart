import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';
import 'chat_screen.dart';

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authServiceProvider).currentUser?.uid;
    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text("Oturum bulunamadı.")));
    }

    final usersStream = ref.watch(userRepositoryProvider).getAllUsersStream(currentUserId);

    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Sohbet Başlat')),
      body: StreamBuilder<List<UserModel>>(
        stream: usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Kullanıcılar yüklenemedi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Listelenecek kullanıcı bulunamadı.'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(user.name),
                subtitle: Text(user.userType == UserType.coach ? 'Koç' : 'Öğrenci'),
                onTap: () async {
                  // Yükleme göstergesi göster (opsiyonel)
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final chatId = await ref.read(firestoreServiceProvider).getOrCreateChat(currentUserId, user.id);
                    
                    if (context.mounted) {
                      Navigator.of(context).pop(); // Dialog'u kapat
                      Navigator.of(context).pushReplacement( // Yeni sohbet ekranına yönlendir ve bu ekranı yığından kaldır
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chatId,
                            recipientName: user.name,
                            recipientId: user.id,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.of(context).pop(); // Dialog'u kapat
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sohbet oluşturulamadı: $e')),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
