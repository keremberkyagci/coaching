// ============================================================
// lib/services/chat_service.dart — Mesajlaşma servisi
//
// FirestoreService'e alternatif/tamamlayıcı bir chat implementasyonu.
// (Ana kodda FirestoreService kullanılmaktadır; bu dosya eski implementasyondur.)
//
//   - getChatsStream      : Kullanıcının tüm sohbet odalarını dinler
//   - getMessagesStream   : Sohbet odasındaki mesajları dinler
//   - createOrGetChat     : İki kullanıcı arasında oda oluştur ya da mevcut olanı bul
//   - sendMessage         : Mesaj gönder, okunmamış sayacını artır (Firestore batch)
//   - markChatAsRead      : Sohbeti okundu yap, mesajları güncelle
//
// Fark: Bu servis participants listesini sıralayarak kesin eşleşme sağlar.
//       FirestoreService.getOrCreateChat() ise arrayContains ile esnek arama yapar.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _chatsCollection = FirebaseFirestore.instance.collection('chats');

  /// Belirli bir kullanıcının dahil olduğu tüm sohbet odalarını gerçek zamanlı olarak dinler.
  Stream<List<ChatModel>> getChatsStream(String userId) {
    return _chatsCollection
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Belirli bir sohbet odasındaki tüm mesajları gerçek zamanlı olarak dinler.
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// İki kullanıcı arasında bir sohbet odası olup olmadığını kontrol eder.
  /// Yoksa, tüm başlangıç alanlarını içeren yeni bir sohbet oluşturur.
  Future<String> createOrGetChat(String currentUserId, String recipientUserId, Map<String, dynamic> currentUserDetails, Map<String, dynamic> recipientUserDetails) async {
    List<String> participants = [currentUserId, recipientUserId]..sort();
    
    QuerySnapshot query = await _chatsCollection
        .where('participants', isEqualTo: participants)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    } else {
      final now = Timestamp.now();
      final newChatData = {
        'participants': participants,
        'participantDetails': {
          currentUserId: currentUserDetails,
          recipientUserId: recipientUserDetails,
        },
        'lastMessage': 'Sohbet başlatıldı.',
        'lastMessageTimestamp': now,
        'lastMessageSenderId': '',
        'unreadCounts': {
          participants[0]: 0,
          participants[1]: 0,
        },
        'lastRead': {
          participants[0]: now,
          participants[1]: now,
        }
      };

      DocumentReference docRef = await _chatsCollection.add(newChatData);
      return docRef.id;
    }
  }

  /// Belirli bir sohbet odasına yeni bir mesaj gönderir ve alıcının okunmamış sayacını artırır.
  Future<void> sendMessage(String chatId, String text, String senderId, String receiverId) async {
    if (text.trim().isEmpty) return;

    final Timestamp timestamp = Timestamp.now();

    final messageData = {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'isRead': false,
    };

    WriteBatch batch = _firestore.batch();

    final messageRef = _chatsCollection.doc(chatId).collection('messages').doc();
    batch.set(messageRef, messageData);

    final chatRef = _chatsCollection.doc(chatId);
    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageTimestamp': timestamp,
      'lastMessageSenderId': senderId,
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Bir sohbeti okundu olarak işaretler, sayacı sıfırlar ve ilgili mesajları günceller.
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      WriteBatch batch = _firestore.batch();

      final chatRef = _chatsCollection.doc(chatId);
      batch.update(chatRef, {
        'unreadCounts.$userId': 0,
        'lastRead.$userId': FieldValue.serverTimestamp(),
      });

      final messagesQuery = chatRef
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false);

      final messagesSnapshot = await messagesQuery.get();

      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      // Hata yönetimi için buraya daha gelişmiş bir loglama mekanizması eklenebilir.
    }
  }
}
