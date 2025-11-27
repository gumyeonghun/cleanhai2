import 'package:cloud_firestore/cloud_firestore.dart';

class CompletionReport {
  final String summary;
  final String details;
  final List<String> imageUrls;
  final DateTime createdAt;

  CompletionReport({
    required this.summary,
    required this.details,
    this.imageUrls = const [],
    required this.createdAt,
  });

  factory CompletionReport.fromMap(Map<String, dynamic> map) {
    return CompletionReport(
      summary: map['summary'] ?? '',
      details: map['details'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'summary': summary,
      'details': details,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
