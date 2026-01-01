// lib/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Kullanıcı türünü belirtir (Öğrenci veya Koç).
enum UserType {
  student,
  coach;

  /// Firestore'dan gelen string'i UserType enum'una çevirir.
  static UserType fromString(String? type) {
    switch (type) {
      case 'coach':
        return UserType.coach;
      case 'student':
      default:
        return UserType.student;
    }
  }
}

/// Abonelik seviyesini belirtir (örn: free, premium).
enum SubscriptionTier {
  free,
  premium; // Gelecekte farklı seviyeler eklenebilir

  /// Firestore'dan gelen string'i SubscriptionTier enum'una çevirir.
  static SubscriptionTier fromString(String? tier) {
    switch (tier) {
      case 'premium':
        return SubscriptionTier.premium;
      case 'free':
      default:
        return SubscriptionTier.free;
    }
  }
}

/// Uygulama kullanıcılarını (öğrenciler ve koçlar) temsil eden, değişmez (immutable) veri modeli.
/// Equatable kullanarak, iki UserModel nesnesinin içerik bazlı karşılaştırmasını sağlar.
class UserModel extends Equatable {
  final String id; // Firestore document ID, önceki 'uid' yerine 'id' kullandık
  final String name;
  final String email;
  final UserType userType; // Artık enum kullanıyoruz
  final String? profileImageUrl; // Resim URL'si eklendi

  // Öğrenciye Özel Alanlar
  final String? examType;
  final String? highSchool;
  final String? targetMajor;
  final String? targetRank;
  final String? coachId; // EKLENEN ALAN

  // Koç'a Özel Alanlar
  final int? yearsOfCoaching;
  final String? biography;
  final Map<String, dynamic>?
      coachConnection; // Koçun bağlı olduğu öğrencilerin bilgisi olabilir

  final SubscriptionTier subscriptionTier; // Abonelik seviyesi için enum

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.profileImageUrl,
    this.examType,
    this.highSchool,
    this.targetMajor,
    this.targetRank,
    this.coachId, // EKLENDİ
    this.yearsOfCoaching,
    this.biography,
    this.coachConnection,
    this.subscriptionTier =
        SubscriptionTier.free, // Varsayılan değer için enum kullanıyoruz
  });

  /// Firestore'dan gelen veriden bir [UserModel] nesnesi oluşturur.
  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return UserModel(
      id: snapshot.id, // uid yerine document id kullanıyoruz
      name: data?['name'] ?? '',
      email: data?['email'] ?? '',
      userType: UserType.fromString(data?['userType']),
      profileImageUrl: data?['profileImageUrl'],

      // Öğrenciye özel alanlar
      examType: data?['examType'],
      highSchool: data?['highSchool'],
      targetMajor: data?['targetMajor'],
      targetRank: data?['targetRank'],
      coachId: data?['coachId'], // EKLENDİ

      // Koç'a özel alanlar
      yearsOfCoaching: data?['yearsOfCoaching'],
      biography: data?['biography'],
      coachConnection: data?['coachConnection'] != null
          ? Map<String, dynamic>.from(data!['coachConnection'])
          : null,

      subscriptionTier: SubscriptionTier.fromString(data?['subscriptionTier']),
    );
  }

  /// Mevcut nesneyi Firestore'a yazılabilecek bir Map'e dönüştürür.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'userType': userType.name, // Enum'ı string olarak kaydet
      'profileImageUrl': profileImageUrl,

      // Öğrenciye özel alanlar
      'examType': examType,
      'highSchool': highSchool,
      'targetMajor': targetMajor,
      'targetRank': targetRank,
      'coachId': coachId, // EKLENDİ

      // Koç'a özel alanlar
      'yearsOfCoaching': yearsOfCoaching,
      'biography': biography,
      'coachConnection': coachConnection,

      'subscriptionTier': subscriptionTier.name, // Enum'ı string olarak kaydet
    };
  }

  /// toMap() alias - toFirestore() ile aynı
  Map<String, dynamic> toMap() => toFirestore();

  /// Map'den UserModel oluşturur
  factory UserModel.fromMap(Map<String, dynamic> data, {String? userId}) {
    return UserModel(
      id: userId ?? data['id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      userType: UserType.fromString(data['userType']),
      profileImageUrl: data['profileImageUrl'],
      examType: data['examType'],
      highSchool: data['highSchool'],
      targetMajor: data['targetMajor'],
      targetRank: data['targetRank'],
      coachId: data['coachId'], // EKLENDİ
      yearsOfCoaching: data['yearsOfCoaching'],
      biography: data['biography'],
      coachConnection: data['coachConnection'] != null
          ? Map<String, dynamic>.from(data['coachConnection'])
          : null,
      subscriptionTier: SubscriptionTier.fromString(data['subscriptionTier']),
    );
  }

  /// Mevcut nesnenin bir kopyasını oluştururken, belirtilen alanları günceller.
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserType? userType,
    String? profileImageUrl,
    String? examType,
    String? highSchool,
    String? targetMajor,
    String? targetRank,
    String? coachId, // EKLENDİ
    int? yearsOfCoaching,
    String? biography,
    Map<String, dynamic>? coachConnection,
    SubscriptionTier? subscriptionTier,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      examType: examType ?? this.examType,
      highSchool: highSchool ?? this.highSchool,
      targetMajor: targetMajor ?? this.targetMajor,
      targetRank: targetRank ?? this.targetRank,
      coachId: coachId ?? this.coachId, // EKLENDİ
      yearsOfCoaching: yearsOfCoaching ?? this.yearsOfCoaching,
      biography: biography ?? this.biography,
      coachConnection: coachConnection ?? this.coachConnection,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
    );
  }

  /// Equatable için karşılaştırmada kullanılacak alanlar.
  @override
  List<Object?> get props => [
        id,
        name,
        email,
        userType,
        profileImageUrl,
        examType,
        highSchool,
        targetMajor,
        targetRank,
        coachId, // EKLENDİ
        yearsOfCoaching,
        biography,
        coachConnection,
        subscriptionTier,
      ];
}
