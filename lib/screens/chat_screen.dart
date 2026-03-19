// ============================================================
// lib/screens/chat_screen.dart — Mesajlaşma ekranı
//
// İki kullanıcı arasındaki mesajları gerçek zamanlı gösterir ve yeni mesaj gönderir.
//
// Akış:
//   - initState: Mevcut kullanıcı bilgisini yükle, eskiden okunmamış mesajları okundu işaretle
//   - chatMessagesProvider(chatId): stream ile mesajları gerçek zamanlı dinle
//   - _sendMessage(): FirestoreService.sendMessage() çağırır (mesaj + sohbet güncelleme)
//
// UI:
//   - _buildMessageItem(): Gönderene göre sağ/sol hizalama, balon tasarımı, tick ikonları
//   - _buildMessageComposer(): Alt kısımdaki metin kutusu + gönder butonu
//   - Mesaj listesi reverse: true ile en son mesaj altta görünür
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String recipientName;
  final String recipientId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.recipientName,
    required this.recipientId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late final String _currentUserId;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    Future.microtask(() {
      _loadCurrentUser();
      ref.read(firestoreServiceProvider).markMessagesAsRead(widget.chatId, _currentUserId);
    });
  }

  Future<void> _loadCurrentUser() async {
    final user = await ref.read(userRepositoryProvider).getUserById(_currentUserId);
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty && _currentUser != null) {
      final text = _messageController.text.trim();
      _messageController.clear();
      
      final message = MessageModel(
        senderId: _currentUserId,
        text: text,
        timestamp: Timestamp.now(),
      );

      ref.read(firestoreServiceProvider).sendMessage(
        widget.chatId,
        message,
        _currentUser!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Riverpod kullanarak mesajları dinliyoruz (StreamBuilder yerine)
    final messagesAsyncValue = ref.watch(chatMessagesProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsyncValue.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('Mesaj göndermeye başla!'));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;
                    return _buildMessageItem(message, isMe);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                debugPrint('Mesajları çekerken hata: $error');
                return Center(child: Text('Mesajlar yüklenemedi: $error'));
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(MessageModel message, bool isMe) {
    final time = DateFormat('HH:mm').format(message.timestamp.toDate());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).primaryColor.withAlpha((255 * 0.9).round())
              : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
                isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.start : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87, fontSize: 16),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withAlpha((255 * 0.7).round())
                          : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                  if (isMe) const SizedBox(width: 5),
                  if (isMe)
                    Icon(
                      Icons.done_all,
                      size: 16,
                      color:
                          message.isRead ? Colors.blue[400] : Colors.grey[300],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                  hintText: 'Mesaj yaz...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10)),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (text) => setState(() {}),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
            onPressed: _messageController.text.trim().isNotEmpty &&
                    _currentUser != null
                ? _sendMessage
                : null,
          ),
        ],
      ),
    );
  }
}
