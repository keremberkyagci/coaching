// lib/models/coach_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Koç kullanıcılarını temsil eden, değişmez (immutable) veri modeli.
/// Equatable kullanarak, iki model nesnesinin içerik bazlı karşılaştırmasını sağlar.
class CoachModel extends Equatable {
  final String? id; // Firestore document ID. Yeni koç oluştururken null olabilir.
  final String name;
  final String email;
  final String? profileImageUrl;
  final String expertiseArea;
  final List<String> studentIds;
  final Map<String, dynamic> availableSlots;
  final double rating;

  const CoachModel({
    this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.expertiseArea,
    required this.studentIds,
    required this.availableSlots,
    required this.rating,
  });

  /// Firestore'dan gelen veriden bir [CoachModel] nesnesi oluşturur.
  factory CoachModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return CoachModel(
      id: snapshot.id,
      name: data?['name'] ?? 'İsimsiz Koç',
      email: data?['email'] ?? '',
      profileImageUrl: data?['profileImageUrl'],
      expertiseArea: data?['expertiseArea'] ?? 'Belirtilmemiş',
      studentIds: List<String>.from(data?['studentIds'] ?? []),
      availableSlots: Map<String, dynamic>.from(data?['availableSlots'] ?? {}),
      // Firestore'da sayı hem int hem double olabilir. 'as num' ile güvenli çevrim yapılır.
      rating: (data?['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Mevcut nesneyi Firestore'a yazılabilecek bir Map'e dönüştürür.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'expertiseArea': expertiseArea,
      'studentIds': studentIds,
      'availableSlots': availableSlots,
      'rating': rating,
    };
  }

  /// Mevcut nesnenin bir kopyasını oluştururken, belirtilen alanları günceller.
  /// State management için kritik öneme sahiptir.
  CoachModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    String? expertiseArea,
    List<String>? studentIds,
    Map<String, dynamic>? availableSlots,
    double? rating,
  }) {
    return CoachModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      // Nullable alanlar için özel kontrol
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      expertiseArea: expertiseArea ?? this.expertiseArea,
      studentIds: studentIds ?? this.studentIds,
      availableSlots: availableSlots ?? this.availableSlots,
      rating: rating ?? this.rating,
    );
  }

  /// Equatable için karşılaştırmada kullanılacak alanlar.
  @override
  List<Object?> get props => [
    id,
    name,
    email,
    profileImageUrl,
    expertiseArea,
    studentIds,
    availableSlots,
    rating
  ];
}