import 'package:cloud_firestore/cloud_firestore.dart';

class CleaningKnowhow {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String? imageUrl;
  final DateTime createdAt;

  CleaningKnowhow({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.imageUrl,
    required this.createdAt,
  });

  factory CleaningKnowhow.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CleaningKnowhow(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      imageUrl: data['imageUrl'],
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
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
