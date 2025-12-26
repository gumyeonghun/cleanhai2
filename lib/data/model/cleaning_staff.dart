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
  final String? detailAddress;
  // latitude, longitude removed
  final List<String>? availableDays; // For auto-registered staff
  final bool isAutoRegistered; // Flag for auto-registered staff
  final String? cleaningType; // Cleaning specialty
  final String? cleaningPrice; // Base cleaning price
  final String? additionalOptionCost; // Additional option costs
  final String? availableStartTime; // New field
  final String? availableEndTime; // New field
  final String? cleaningDuration;

  CleaningStaff({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    this.imageUrl,
    this.address,
    this.detailAddress,
    // latitude, longitude removed
    required this.createdAt,
    required this.updatedAt,
    this.availableDays,
    this.isAutoRegistered = false,
    this.cleaningType,
    this.cleaningPrice,
    this.additionalOptionCost,
    this.availableStartTime,
    this.availableEndTime,
    this.cleaningDuration,
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
      detailAddress: data['detailAddress'],
      // latitude: data['latitude'], // Removed
      // longitude: data['longitude'], // Removed
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      availableDays: data['availableDays'] != null ? List<String>.from(data['availableDays']) : null,
      isAutoRegistered: data['isAutoRegistered'] ?? false,
      cleaningType: data['cleaningType'],
      cleaningPrice: data['cleaningPrice'],
      additionalOptionCost: data['additionalOptionCost'],
      availableStartTime: data['availableStartTime'],
      availableEndTime: data['availableEndTime'],
      cleaningDuration: data['cleaningDuration'],
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
      'detailAddress': detailAddress,
      // 'latitude': latitude, // Removed
      // 'longitude': longitude, // Removed
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'availableDays': availableDays,
      'isAutoRegistered': isAutoRegistered,
      'cleaningType': cleaningType,
      'cleaningPrice': cleaningPrice,
      'additionalOptionCost': additionalOptionCost,
      'availableStartTime': availableStartTime,
      'availableEndTime': availableEndTime,
      'cleaningDuration': cleaningDuration,
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
    String? detailAddress,
    // latitude, longitude removed
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? availableDays,
    bool? isAutoRegistered,
    String? cleaningType,
    String? cleaningPrice,
    String? additionalOptionCost,
    String? availableStartTime,
    String? availableEndTime,
    String? cleaningDuration,
  }) {
    return CleaningStaff(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      detailAddress: detailAddress ?? this.detailAddress,
      // latitude: latitude ?? this.latitude, // Removed
      // longitude: longitude ?? this.longitude, // Removed
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      availableDays: availableDays ?? this.availableDays,
      isAutoRegistered: isAutoRegistered ?? this.isAutoRegistered,
      cleaningType: cleaningType ?? this.cleaningType,
      cleaningPrice: cleaningPrice ?? this.cleaningPrice,
      additionalOptionCost: additionalOptionCost ?? this.additionalOptionCost,
      availableStartTime: availableStartTime ?? this.availableStartTime,
      availableEndTime: availableEndTime ?? this.availableEndTime,
      cleaningDuration: cleaningDuration ?? this.cleaningDuration,
    );
  }
}
