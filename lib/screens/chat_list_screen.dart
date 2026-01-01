import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import 'chat_screen.dart';
import 'users_list_screen.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.isAfter(today)) {
      return DateFormat.Hm('tr_TR').format(date);
    } else if (date.isAfter(yesterday)) {
      return 'Dün';
    } else {
      return DateFormat.yMd('tr_TR').format(date);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authServiceProvider).currentUser?.uid;
    
    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text("Oturum bulunamadı.")));
    }
    
    final chatsAsyncValue = ref.watch(chatsProvider(currentUserId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbetler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Yeni Sohbet Başlat',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const UsersListScreen()));
            },
          ),
        ],
      ),
      body: chatsAsyncValue.when(
        data: (chats) {
          if (chats.isEmpty) {
            return const Center(child: Text('Henüz bir sohbetiniz yok.'));
          }
          
          chats.sort((a, b) {
            final aTime = a.lastMessageTimestamp;
            final bTime = b.lastMessageTimestamp;

            if (bTime == null) return -1;
            if (aTime == null) return 1;
            return bTime.compareTo(aTime);
          });
          
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final recipientId = chat.participants.firstWhereOrNull((id) => id != currentUserId);
              final recipient = chat.participantDetails[recipientId];
              final bool isUnread = (chat.unreadCounts[currentUserId] ?? 0) > 0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (recipient?.profileImageUrl != null)
                      ? NetworkImage(recipient!.profileImageUrl!)
                      : null,
                  child: (recipient?.profileImageUrl == null)
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(
                  recipient?.displayName ?? 'Bilinmeyen Kullanıcı',
                  style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
                ),
                subtitle: Text(
                  chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (chat.lastMessageTimestamp != null)
                      Text(_formatTimestamp(chat.lastMessageTimestamp!.toDate()), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (isUnread)
                      const SizedBox(height: 4),
                    if (isUnread)
                      const CircleAvatar(radius: 5, backgroundColor: Colors.green),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatId: chat.id,
                      recipientName: recipient?.displayName ?? 'Bilinmeyen Kullanıcı',
                      recipientId: recipientId ?? '',
                    ),
                  ));
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Sohbetler yüklenemedi: $err')),
      ),
    );
  }
}