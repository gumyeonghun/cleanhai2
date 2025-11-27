import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressNote {
  final String note;
  final DateTime createdAt;
  final String createdBy;

  ProgressNote({
    required this.note,
    required this.createdAt,
    required this.createdBy,
  });

  factory ProgressNote.fromMap(Map<String, dynamic> map) {
    return ProgressNote(
      note: map['note'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
}
