import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Bir dersin altındaki tek bir konuyu temsil eden, değişmez (immutable) veri modeli.
/// Konuların sıralanması için bir 'order' alanı içerir.
class TopicModel extends Equatable {
  final String? id; // Firestore document ID
  final String name;
  final String? group; // Konunun ait olduğu ders/grup adı
  final int? order; // Konuların sıralanmasını sağlamak için

  const TopicModel({
    this.id,
    required this.name,
    this.group,
    this.order,
  });

  /// Firestore'dan gelen veriden bir [TopicModel] nesnesi oluşturur.
  factory TopicModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return TopicModel(
      id: snapshot.id,
      name: data?['name'] ?? 'İsimsiz Konu',
      group: data?['group'],
      order: data?['order'],
    );
  }

  /// Map'den TopicModel oluşturur
  factory TopicModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TopicModel(
      id: documentId,
      name: data['name'] ?? 'İsimsiz Konu',
      group: data['group'],
      order: data['order'],
    );
  }

  /// Mevcut nesneyi Firestore'a yazılabilecek bir Map'e dönüştürür.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'group': group,
      'order': order,
    };
  }

  /// Mevcut nesnenin bir kopyasını oluştururken, belirtilen alanları günceller.
  TopicModel copyWith({
    String? id,
    String? name,
    String? group,
    int? order,
  }) {
    return TopicModel(
      id: id ?? this.id,
      name: name ?? this.name,
      group: group ?? this.group,
      order: order ?? this.order,
    );
  }

  /// Equatable için karşılaştırmada kullanılacak alanlar.
  @override
  List<Object?> get props => [id, name, group, order];
}
