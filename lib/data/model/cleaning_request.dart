import 'package:cloud_firestore/cloud_firestore.dart';
import 'progress_note.dart';
import 'completion_report.dart';
import 'review.dart';

class CleaningRequest {
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
  final double? latitude;
  final double? longitude;
  final String? price;
  final List<String> applicants;
  final String? acceptedApplicantId;
  final String? paymentStatus; // 'pending', 'completed', 'failed'
  final String? paymentKey;
  final String? orderId;
  final DateTime? paidAt;
  final String status; // 'pending', 'in_progress', 'completed'
  final List<ProgressNote> progressNotes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final CompletionReport? completionReport;
  final Review? review;
  final String? targetStaffId; // For direct requests
  final List<String>? availableDays; // For auto-registered requests
  final bool isAutoRegistered; // Flag for auto-registered requests
  final String? cleaningType; // Cleaning type
  final String? requesterName;
  final String? cleaningToolLocation;
  final String? precautions;
  final DateTime? cleaningDate;

  CleaningRequest({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    this.imageUrl,
    this.address,
    this.detailAddress,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.price,
    this.applicants = const [],
    this.acceptedApplicantId,
    this.paymentStatus,
    this.paymentKey,
    this.orderId,
    this.paidAt,
    this.status = 'pending',
    this.progressNotes = const [],
    this.startedAt,
    this.completedAt,
    this.completionReport,
    this.review,
    this.targetStaffId,
    this.availableDays,
    this.isAutoRegistered = false,
    this.cleaningType,
    this.requesterName,
    this.cleaningToolLocation,
    this.precautions,
    this.cleaningDate,
  });

  // Firestore에서 데이터를 가져올 때 사용
  factory CleaningRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CleaningRequest(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      address: data['address'],
      detailAddress: data['detailAddress'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      price: data['price'],
      applicants: List<String>.from(data['applicants'] ?? []),
      acceptedApplicantId: data['acceptedApplicantId'],
      paymentStatus: data['paymentStatus'],
      paymentKey: data['paymentKey'],
      orderId: data['orderId'],
      paidAt: data['paidAt'] != null ? (data['paidAt'] as Timestamp).toDate() : null,
      status: data['status'] ?? 'pending',
      progressNotes: (data['progressNotes'] as List<dynamic>?)?.map((e) => ProgressNote.fromMap(e as Map<String, dynamic>)).toList() ?? [],
      startedAt: data['startedAt'] != null ? (data['startedAt'] as Timestamp).toDate() : null,
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      completionReport: data['completionReport'] != null ? CompletionReport.fromMap(data['completionReport']) : null,
      review: data['review'] != null ? Review.fromMap(data['review']) : null,
      targetStaffId: data['targetStaffId'],
      availableDays: data['availableDays'] != null ? List<String>.from(data['availableDays']) : null,
      isAutoRegistered: data['isAutoRegistered'] ?? false,
      cleaningType: data['cleaningType'],
      requesterName: data['requesterName'],
      cleaningToolLocation: data['cleaningToolLocation'],
      precautions: data['precautions'],
      cleaningDate: data['cleaningDate'] != null ? (data['cleaningDate'] as Timestamp).toDate() : null,
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
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'price': price,
      'applicants': applicants,
      'acceptedApplicantId': acceptedApplicantId,
      'paymentStatus': paymentStatus,
      'paymentKey': paymentKey,
      'orderId': orderId,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'status': status,
      'progressNotes': progressNotes.map((e) => e.toMap()).toList(),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completionReport': completionReport?.toMap(),
      'review': review?.toMap(),
      'targetStaffId': targetStaffId,
      'availableDays': availableDays,
      'isAutoRegistered': isAutoRegistered,
      'cleaningType': cleaningType,
      'requesterName': requesterName,
      'cleaningToolLocation': cleaningToolLocation,
      'precautions': precautions,
      'cleaningDate': cleaningDate != null ? Timestamp.fromDate(cleaningDate!) : null,
    };
  }

  // 복사본 생성 (수정 시 사용)
  CleaningRequest copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? title,
    String? content,
    String? imageUrl,
    String? address,
    String? detailAddress,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? price,
    List<String>? applicants,
    String? acceptedApplicantId,
    String? paymentStatus,
    String? paymentKey,
    String? orderId,
    DateTime? paidAt,
    String? status,
    List<ProgressNote>? progressNotes,
    DateTime? startedAt,
    DateTime? completedAt,
    CompletionReport? completionReport,
    Review? review,
    String? targetStaffId,
    List<String>? availableDays,
    bool? isAutoRegistered,
    String? cleaningType,
    String? requesterName,
    String? cleaningToolLocation,
    String? precautions,
    DateTime? cleaningDate,
  }) {
    return CleaningRequest(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      detailAddress: detailAddress ?? this.detailAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      price: price ?? this.price,
      applicants: applicants ?? this.applicants,
      acceptedApplicantId: acceptedApplicantId ?? this.acceptedApplicantId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentKey: paymentKey ?? this.paymentKey,
      orderId: orderId ?? this.orderId,
      paidAt: paidAt ?? this.paidAt,
      status: status ?? this.status,
      progressNotes: progressNotes ?? this.progressNotes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      completionReport: completionReport ?? this.completionReport,
      review: review ?? this.review,
      targetStaffId: targetStaffId ?? this.targetStaffId,
      availableDays: availableDays ?? this.availableDays,
      isAutoRegistered: isAutoRegistered ?? this.isAutoRegistered,
      cleaningType: cleaningType ?? this.cleaningType,
      requesterName: requesterName ?? this.requesterName,
      cleaningToolLocation: cleaningToolLocation ?? this.cleaningToolLocation,
      precautions: precautions ?? this.precautions,
      cleaningDate: cleaningDate ?? this.cleaningDate,
    );
  }
}
