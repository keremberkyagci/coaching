import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Bir dersi ve ait olabileceği grubu temsil eden, değişmez (immutable) veri modeli.
class LessonModel extends Equatable {
  final String? id; // Firestore document ID
  final String name;
  final String? type; // Dersin türü (örn: "TYT", "AYT")

  const LessonModel({
    this.id,
    required this.name,
    this.type,
  });

  /// Firestore'dan gelen veriden bir [LessonModel] nesnesi oluşturur.
  factory LessonModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return LessonModel(
      id: snapshot.id,
      name: data?['name'] ?? 'İsimsiz Ders',
      type: data?['type'],
    );
  }

  /// Map'den LessonModel oluşturur
  factory LessonModel.fromMap(Map<String, dynamic> data, String documentId) {
    return LessonModel(
      id: documentId,
      name: data['name'] ?? 'İsimsiz Ders',
      type: data['type'],
    );
  }

  /// Mevcut nesneyi Firestore'a yazılabilecek bir Map'e dönüştürür.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
    };
  }

  /// Mevcut nesnenin bir kopyasını oluştururken, belirtilen alanları günceller.
  LessonModel copyWith({
    String? id,
    String? name,
    String? type,
  }) {
    return LessonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  /// Equatable için karşılaştırmada kullanılacak alanlar.
  @override
  List<Object?> get props => [id, name, type];
}
