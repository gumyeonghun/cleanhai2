import 'package:cloud_firestore/cloud_firestore.dart';

class CleaningRecommendation {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String? imageUrl;
  final String? address; // Optional: Neighborhood context
  final DateTime createdAt;

  CleaningRecommendation({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.imageUrl,
    this.address,
    required this.createdAt,
  });

  factory CleaningRecommendation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CleaningRecommendation(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      imageUrl: data['imageUrl'],
      address: data['address'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'imageUrl': imageUrl,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
