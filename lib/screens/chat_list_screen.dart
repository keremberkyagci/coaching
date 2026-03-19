// ============================================================
// lib/screens/chat_list_screen.dart — Sohbet listesi ekranı
//
// Mevcut kullanıcının dahil olduğu tüm sohbet odalarını listeler.
// chatsProvider (stream) ile gerçek zamanlı güncellenir.
//
// Özellikler:
//   - Sohbetler son mesaj zamanına göre azalan sırada listelenir
//   - Okunmamış mesajlar bold + yeşil nokta ile işaretlenir
//   - Koç sohbetleri kırmızı, öğrenci sohbetleri turuncu kartlarla gösterilir
//   - (+) butonu ile _NewChatDialog açılır: kullanıcı ID girerek yeni sohbet başlatılır
//
// _NewChatDialog:
//   - Arama: getUserById() ile ID varlığını doğrular
//   - Oluşturma: getOrCreateChat() ile var olan ya da yeni sohbet odasına gider
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';
import 'chat_screen.dart';

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
              showDialog(
                context: context,
                builder: (context) => _NewChatDialog(currentUserId: currentUserId),
              );
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

              return FutureBuilder<UserModel?>(
                future: recipientId != null 
                    ? ref.read(userRepositoryProvider).getUserById(recipientId)
                    : Future.value(null),
                builder: (context, snapshot) {
                  final recipientUserType = snapshot.data?.userType;
                  
                  Color? tileColor = Colors.white;
                  if (recipientUserType == UserType.coach) {
                    tileColor = Colors.red[100];
                  } else if (recipientUserType == UserType.student) {
                    tileColor = Colors.orange[100];
                  }

                  return Card(
                    color: tileColor,
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
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
                            Text(_formatTimestamp(chat.lastMessageTimestamp!.toDate()), style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
                    ),
                  );
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

class _NewChatDialog extends ConsumerStatefulWidget {
  final String currentUserId;
  const _NewChatDialog({required this.currentUserId});

  @override
  ConsumerState<_NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends ConsumerState<_NewChatDialog> {
  final _idController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _startChat() async {
    final targetId = _idController.text.trim();
    if (targetId.isEmpty) {
      setState(() => _errorText = 'Lütfen bir Kullanıcı ID girin.');
      return;
    }
    if (targetId == widget.currentUserId) {
      setState(() => _errorText = 'Kendinizle sohbet başlatamazsınız.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final user = await ref.read(userRepositoryProvider).getUserById(targetId, forceRefresh: true);
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorText = 'Bu ID ile bir kullanıcı bulunamadı.';
          });
        }
        return;
      }

      final chatId = await ref.read(firestoreServiceProvider).getOrCreateChat(widget.currentUserId, user.id);
      
      if (mounted) {
        Navigator.of(context).pop(); // Dialog'u kapat
        Navigator.of(context).push(
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = 'Bir hata oluştu: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Sohbet Başlat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Sohbet başlatmak istediğiniz kişinin Kullanıcı ID\'sini girin.'),
          const SizedBox(height: 16),
          TextField(
            controller: _idController,
            decoration: InputDecoration(
              labelText: 'Kullanıcı ID',
              errorText: _errorText,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _startChat,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Başlat'),
        ),
      ],
    );
  }
}