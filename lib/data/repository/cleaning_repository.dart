import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../model/cleaning_request.dart';
import '../model/cleaning_staff.dart';
import '../model/user_model.dart';
import '../model/progress_note.dart';
import '../model/completion_report.dart';
import '../model/review.dart';

class CleaningRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 컬렉션 참조
  CollectionReference get _cleaningRequestsRef =>
      _firestore.collection('cleaning_requests');
  CollectionReference get _cleaningStaffsRef =>
      _firestore.collection('cleaning_staffs');

  // ==================== 청소 의뢰 관련 메서드 ====================

  /// 청소 의뢰 생성
  Future<void> createCleaningRequest(CleaningRequest request) async {
    await _cleaningRequestsRef.add(request.toFirestore());
  }

  /// 청소 의뢰 목록 스트림 (최신순)
  Stream<List<CleaningRequest>> getCleaningRequests() {
    return _cleaningRequestsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CleaningRequest.fromFirestore(doc))
          .toList();
    });
  }

  /// 청소 의뢰 단일 조회
  Future<CleaningRequest?> getCleaningRequestById(String id) async {
    DocumentSnapshot doc = await _cleaningRequestsRef.doc(id).get();
    if (doc.exists) {
      return CleaningRequest.fromFirestore(doc);
    }
    return null;
  }

  /// 청소 의뢰 수정
  Future<void> updateCleaningRequest(CleaningRequest request) async {
    await _cleaningRequestsRef.doc(request.id).update(request.toFirestore());
  }

  /// 청소 의뢰 삭제
  Future<void> deleteCleaningRequest(String id) async {
    await _cleaningRequestsRef.doc(id).delete();
  }

  /// 청소 의뢰 지원
  Future<void> applyForCleaning(String requestId, String userId) async {
    await _cleaningRequestsRef.doc(requestId).update({
      'applicants': FieldValue.arrayUnion([userId]),
    });
  }

  /// 청소 의뢰 지원자 수락 (결제 정보 포함)
  Future<void> acceptApplicant(
    String requestId,
    String applicantId, {
    String? paymentKey,
    String? orderId,
    String? paymentStatus,
  }) async {
    final updateData = {
      'acceptedApplicantId': applicantId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (paymentKey != null) updateData['paymentKey'] = paymentKey;
    if (orderId != null) updateData['orderId'] = orderId;
    if (paymentStatus != null) updateData['paymentStatus'] = paymentStatus;
    if (paymentStatus == 'completed') {
      updateData['paidAt'] = FieldValue.serverTimestamp();
    }

    await _cleaningRequestsRef.doc(requestId).update(updateData);
  }


  /// 내가 의뢰한 청소 중 수락된 것들 (의뢰자 입장)
  Stream<List<CleaningRequest>> getMyAcceptedRequestsAsOwner(String userId) {
    return _cleaningRequestsRef
        .where('authorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CleaningRequest.fromFirestore(doc))
          .where((request) => request.acceptedApplicantId != null)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// 내가 수락된 청소 의뢰들 (청소 직원 입장)
  Stream<List<CleaningRequest>> getMyAcceptedRequestsAsStaff(String userId) {
    return _cleaningRequestsRef
        .where('acceptedApplicantId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CleaningRequest.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// 내가 신청한 모든 청소 의뢰들 (청소 직원 입장 - 대기중 + 수락됨)
  Stream<List<CleaningRequest>> getMyAppliedRequestsAsStaff(String userId) {
    return _cleaningRequestsRef
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CleaningRequest.fromFirestore(doc))
          .where((request) => request.applicants.contains(userId))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// 청소 진행 상태 업데이트
  Future<void> updateCleaningStatus(String requestId, String status) async {
    final updateData = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'in_progress') {
      updateData['startedAt'] = FieldValue.serverTimestamp();
    } else if (status == 'completed') {
      updateData['completedAt'] = FieldValue.serverTimestamp();
    }

    await _cleaningRequestsRef.doc(requestId).update(updateData);
  }

  /// 청소 진행 메모 추가
  Future<void> addProgressNote(String requestId, ProgressNote note) async {
    await _cleaningRequestsRef.doc(requestId).update({
      'progressNotes': FieldValue.arrayUnion([note.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 청소 의뢰 실시간 스트림 (단일)
  Stream<CleaningRequest?> getCleaningRequestStream(String id) {
    return _cleaningRequestsRef.doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return CleaningRequest.fromFirestore(doc);
      }
      return null;
    });
  }

  /// 청소 완료 보고서 제출
  Future<void> submitCompletionReport(String requestId, CompletionReport report) async {
    await _cleaningRequestsRef.doc(requestId).update({
      'completionReport': report.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 리뷰 제출
  Future<void> submitReview(String requestId, Review review) async {
    await _cleaningRequestsRef.doc(requestId).update({
      'review': review.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== 청소 대기 관련 메서드 ====================

  /// 청소 대기 생성
  Future<void> createCleaningStaff(CleaningStaff staff) async {
    await _cleaningStaffsRef.add(staff.toFirestore());
  }

  /// 청소 대기 목록 스트림 (최신순)
  Stream<List<CleaningStaff>> getCleaningStaffs() {
    return _cleaningStaffsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CleaningStaff.fromFirestore(doc))
          .toList();
    });
  }

  /// 청소 대기 단일 조회
  Future<CleaningStaff?> getCleaningStaffById(String id) async {
    DocumentSnapshot doc = await _cleaningStaffsRef.doc(id).get();
    if (doc.exists) {
      return CleaningStaff.fromFirestore(doc);
    }
    return null;
  }

  /// 청소 대기 수정
  Future<void> updateCleaningStaff(CleaningStaff staff) async {
    await _cleaningStaffsRef.doc(staff.id).update(staff.toFirestore());
  }

  /// 청소 대기 삭제
  Future<void> deleteCleaningStaff(String id) async {
    await _cleaningStaffsRef.doc(id).delete();
  }

  /// 대기 중인 청소 직원 목록 조회 (users 컬렉션에서 userType == 'staff' 조회)
  Future<List<CleaningStaff>> getWaitingStaff() async {
    try {
      final snapshot = await _cleaningStaffsRef
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CleaningStaff.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error loading waiting staff: $e');
      return [];
    }
  }

  // ==================== 이미지 업로드 ====================

  /// 이미지를 Firebase Storage에 업로드하고 URL 반환
  Future<String?> uploadImage(File imageFile, String type) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('cleaning_service/$type/$fileName');
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('이미지 업로드 실패: $e');
      return null;
    }
  }

  /// 이미지 삭제
  Future<void> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('이미지 삭제 실패: $e');
    }
  }
    // ==================== 사용자 프로필 관련 메서드 ====================
  CollectionReference get _usersRef => _firestore.collection('users');

  Future<UserModel?> getUserProfile(String uid) async {
    DocumentSnapshot doc = await _usersRef.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _usersRef.doc(user.id).set(user.toFirestore(), SetOptions(merge: true));
  }
}

