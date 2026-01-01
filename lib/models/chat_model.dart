import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// YENİ YARDIMCI MODEL: Katılımcıların denormalize edilmiş bilgilerini type-safe olarak tutar.
class ParticipantDetailModel extends Equatable {
  final String displayName;
  final String? profileImageUrl;

  const ParticipantDetailModel({
    required this.displayName,
    this.profileImageUrl,
  });

  // Map'ten ParticipantDetailModel oluşturur.
  factory ParticipantDetailModel.fromMap(Map<String, dynamic> map) {
    return ParticipantDetailModel(
      displayName: map['displayName'] ?? '',
      profileImageUrl: map['profileImageUrl'],
    );
  }

  // ParticipantDetailModel'i Map'e dönüştürür.
  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
    };
  }
  
  @override
  List<Object?> get props => [displayName, profileImageUrl];
}


// ANA CHAT MODELİ GÜNCELLENDİ
class ChatModel extends Equatable {
  final String id;
  final List<String> participants;
  
  // GÜNCELLENDİ: Artık Map<String, dynamic> yerine Map<String, ParticipantDetailModel> kullanıyoruz.
  // Bu, participantDetails['userId'].displayName gibi güvenli erişim sağlar.
  final Map<String, ParticipantDetailModel> participantDetails;
  
  final String lastMessage;
  final Timestamp? lastMessageTimestamp;
  final String lastMessageSenderId;
  final Map<String, int> unreadCounts;
  final Map<String, Timestamp> lastRead;

  const ChatModel({
    required this.id,
    required this.participants,
    required this.participantDetails,
    required this.lastMessage,
    this.lastMessageTimestamp,
    required this.lastMessageSenderId,
    required this.unreadCounts,
    required this.lastRead,
  });

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    Map<String, ParticipantDetailModel>? participantDetails,
    String? lastMessage,
    Timestamp? lastMessageTimestamp,
    String? lastMessageSenderId,
    Map<String, int>? unreadCounts,
    Map<String, Timestamp>? lastRead,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantDetails: participantDetails ?? this.participantDetails,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      lastRead: lastRead ?? this.lastRead,
    );
  }

  factory ChatModel.fromMap(Map<String, dynamic> data, String documentId) {
    // GÜNCELLENDİ: İç içe geçmiş haritayı ParticipantDetailModel nesnelerine dönüştürüyoruz.
    final participantDetailsData = data['participantDetails'] as Map<String, dynamic>? ?? {};
    final participantDetails = participantDetailsData.map(
      (key, value) => MapEntry(
        key,
        ParticipantDetailModel.fromMap(value as Map<String, dynamic>),
      ),
    );

    return ChatModel(
      id: documentId,
      participants: List<String>.from(data['participants'] ?? []),
      participantDetails: participantDetails,
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTimestamp: data['lastMessageTimestamp'] as Timestamp?,
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      lastRead: (data['lastRead'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as Timestamp)) ??
          {},
    );
  }

  Map<String, dynamic> toMap() {
    // GÜNCELLENDİ: ParticipantDetailModel nesnelerini tekrar Firestore'a uygun Map'lere dönüştürüyoruz.
    final participantDetailsForFirestore = participantDetails.map(
      (key, value) => MapEntry(key, value.toMap()),
    );
    
    return {
      'participants': participants,
      'participantDetails': participantDetailsForFirestore,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCounts': unreadCounts,
      'lastRead': lastRead,
    };
  }

  @override
  List<Object?> get props => [
        id,
        participants,
        participantDetails,
        lastMessage,
        lastMessageTimestamp,
        lastMessageSenderId,
        unreadCounts,
        lastRead,
      ];
}