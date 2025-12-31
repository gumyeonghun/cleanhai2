import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String reporterId; // 신고자 ID
  final String targetId; // 신고 대상 ID (게시글 ID, 리뷰 ID 등)
  final String targetType; // 'cleaning_request', 'cleaning_staff', 'review', 'user'
  final String reason; // 신고 사유
  final DateTime createdAt;
  final String? description; // 추가 설명 (선택)

  Report({
    required this.id,
    required this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.reason,
    required this.createdAt,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'targetId': targetId,
      'targetType': targetType,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
      'description': description,
    };
  }

  factory Report.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      targetId: data['targetId'] ?? '',
      targetType: data['targetType'] ?? 'unknown',
      reason: data['reason'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      description: data['description'],
    );
  }
}
