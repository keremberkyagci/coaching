import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Bir sohbet içindeki tek bir mesajı temsil eden, değişmez (immutable) veri modeli.
class MessageModel extends Equatable {
  final String? id; // Firestore document ID
  final String senderId;
  final String text;
  final Timestamp timestamp;
  final bool isRead;
  final String? imageUrl; // Gelecekte resim gönderme özelliği için eklendi
  final String? fileUrl; // Gelecekte dosya gönderme özelliği için eklendi

  const MessageModel({
    this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false, // Yeni mesajların varsayılanı 'okunmadı' olmalı
    this.imageUrl,
    this.fileUrl,
  });

  /// Firestore'dan gelen veriden bir [MessageModel] nesnesi oluşturur.
  factory MessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return MessageModel(
      id: snapshot.id,
      senderId: data?['senderId'] ?? '',
      text: data?['text'] ?? '',
      timestamp: data?['timestamp'] ?? Timestamp.now(),
      isRead: data?['isRead'] ?? false,
      imageUrl: data?['imageUrl'],
      fileUrl: data?['fileUrl'],
    );
  }

  factory MessageModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MessageModel(
      id: documentId,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
      imageUrl: data['imageUrl'],
      fileUrl: data['fileUrl'],
    );
  }

  /// Mevcut nesneyi Firestore'a yazılabilecek bir Map'e dönüştürür.
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'isRead': isRead,
      // Sadece null olmayan değerleri Firestore'a yazarak maliyeti düşürürüz
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (fileUrl != null) 'fileUrl': fileUrl,
    };
  }

  /// Mevcut nesnenin bir kopyasını oluştururken, belirtilen alanları günceller.
  /// Bir mesajın durumunu (örn: isRead) değiştirmek için idealdir.
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? text,
    Timestamp? timestamp,
    bool? isRead,
    String? imageUrl,
    String? fileUrl,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
    );
  }

  /// Equatable için karşılaştırmada kullanılacak alanlar.
  @override
  List<Object?> get props =>
      [id, senderId, text, timestamp, isRead, imageUrl, fileUrl];
}
