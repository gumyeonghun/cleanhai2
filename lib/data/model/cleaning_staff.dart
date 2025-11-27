import 'package:cloud_firestore/cloud_firestore.dart';

class CleaningStaff {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? address;
  final double? latitude;
  final double? longitude;

  CleaningStaff({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    this.imageUrl,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  // Firestore에서 데이터를 가져올 때 사용
  factory CleaningStaff.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CleaningStaff(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      address: data['address'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Firestore에 데이터를 저장할 때 사용
  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // 복사본 생성 (수정 시 사용)
  CleaningStaff copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? title,
    String? content,
    String? imageUrl,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CleaningStaff(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
