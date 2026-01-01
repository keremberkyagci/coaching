import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Öğrenci kullanıcılarını temsil eden, değişmez (immutable) veri modeli.
class StudentModel extends Equatable {
  final String? id; // Firestore document ID
  final String name;
  final String email;
  final String? profileImageUrl;
  final String schoolName;
  final int grade; // Sınıf (örn: 11, 12)
  final String? coachId; // Atanmış koçun ID'si

  const StudentModel({
    this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.schoolName,
    required this.grade,
    this.coachId,
  });

  /// Firestore'dan gelen veriden bir [StudentModel] nesnesi oluşturur.
  factory StudentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return StudentModel(
      id: snapshot.id,
      name: data?['name'] ?? 'İsimsiz Öğrenci',
      email: data?['email'] ?? '',
      profileImageUrl: data?['profileImageUrl'],
      schoolName: data?['schoolName'] ?? 'Okul Belirtilmemiş',
      grade: data?['grade'] ?? 0,
      coachId: data?['coachId'],
    );
  }

  /// Mevcut nesneyi Firestore'a yazılabilecek bir Map'e dönüştürür.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'schoolName': schoolName,
      'grade': grade,
      'coachId': coachId,
    };
  }

  /// Mevcut nesnenin bir kopyasını oluştururken, belirtilen alanları günceller.
  StudentModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    String? schoolName,
    int? grade,
    String? coachId,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      schoolName: schoolName ?? this.schoolName,
      grade: grade ?? this.grade,
      coachId: coachId ?? this.coachId,
    );
  }

  /// Equatable için karşılaştırmada kullanılacak alanlar.
  @override
  List<Object?> get props => [id, name, email, profileImageUrl, schoolName, grade, coachId];
}