import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:io';
import '../model/cleaning_request.dart';
import '../model/cleaning_staff.dart';
import '../model/user_model.dart';
import '../model/progress_note.dart';
import '../model/completion_report.dart';
import '../model/review.dart';
import '../model/cleaning_knowhow.dart';
import '../model/cleaning_recommendation.dart';

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

  /// 청소 의뢰 목록 스트림 (최신순, 최대 50개)
  Stream<List<CleaningRequest>> getCleaningRequests() {
    return _cleaningRequestsRef
        .orderBy('createdAt', descending: true)
        .limit(50)
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
    String? price,
  }) async {
    final updateData = {
      'acceptedApplicantId': applicantId,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (paymentKey != null) updateData['paymentKey'] = paymentKey;
    if (orderId != null) updateData['orderId'] = orderId;
    if (paymentStatus != null) updateData['paymentStatus'] = paymentStatus;
    if (price != null) updateData['price'] = price;
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

  /// 내가 의뢰한 모든 청소 (대기중 + 수락됨)
  Stream<List<CleaningRequest>> getAllMyRequestsAsOwner(String userId) {
    return _cleaningRequestsRef
        .where('authorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CleaningRequest.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// 내가 의뢰하고 완료된 청소 (의뢰인 입장 - 지불 내역용)
  Stream<List<CleaningRequest>> getMyCompletedRequestsAsOwner(String userId) {
    return _cleaningRequestsRef
        .where('authorId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CleaningRequest.fromFirestore(doc))
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

  /// 내가 완료한 청소 의뢰들 (청소 직원 입장 - 정산용)
  Stream<List<CleaningRequest>> getMyCompletedRequestsAsStaff(String userId) {
    return _cleaningRequestsRef
        .where('acceptedApplicantId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CleaningRequest.fromFirestore(doc))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// 내가 신청한 모든 청소 의뢰들 (청소 직원 입장 - 대기중 + 수락됨)
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

  /// 나에게 직접 들어온 청소 의뢰들 (청소 직원 입장)
  Stream<List<CleaningRequest>> getMyTargetedRequestsAsStaff(String userId) {
    return _cleaningRequestsRef
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CleaningRequest.fromFirestore(doc))
          .where((request) => request.targetStaffId == userId)
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

  /// 작성자 ID로 청소 의뢰 조회 (최근 1개)
  Future<CleaningRequest?> getCleaningRequestByAuthorId(String authorId) async {
    try {
      final snapshot = await _cleaningRequestsRef
          .where('authorId', isEqualTo: authorId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return CleaningRequest.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting request by author id: $e');
      return null;
    }
  }

  /// 작성자 ID로 청소 의뢰 삭제 (자동 등록된 것만 삭제하는 것이 이상적이지만, 여기서는 가장 최근 것을 삭제하거나 로직에 따라 처리)
  /// 주의: 이 메서드는 해당 사용자의 모든 의뢰를 삭제할 수 있으므로 신중해야 함.
  /// 여기서는 자동 등록 로직을 위해 'pending' 상태인 가장 최근 의뢰 1개를 삭제하도록 구현
  Future<void> deleteCleaningRequestByAuthorId(String authorId) async {
    try {
      final snapshot = await _cleaningRequestsRef
          .where('authorId', isEqualTo: authorId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting request by author id: $e');
    }
  }

  // ==================== 청소 대기 관련 메서드 ====================

  /// 청소 대기 생성
  Future<void> createCleaningStaff(CleaningStaff staff) async {
    await _cleaningStaffsRef.add(staff.toFirestore());
  }

  /// 청소 대기 목록 스트림 (최신순, 최대 50개)
  Stream<List<CleaningStaff>> getCleaningStaffs() {
    return _cleaningStaffsRef
        .orderBy('createdAt', descending: true)
        .limit(50)
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
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => CleaningStaff.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error loading waiting staff: $e');
      return [];
    }
  }

  /// 작성자 ID로 청소 대기 조회
  Future<CleaningStaff?> getCleaningStaffByAuthorId(String authorId) async {
    try {
      final snapshot = await _cleaningStaffsRef
          .where('authorId', isEqualTo: authorId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return CleaningStaff.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting staff by author id: $e');
      return null;
    }
  }

  /// 작성자 ID로 청소 대기 삭제
  Future<void> deleteCleaningStaffByAuthorId(String authorId) async {
    try {
      final snapshot = await _cleaningStaffsRef
          .where('authorId', isEqualTo: authorId)
          .get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting staff by author id: $e');
    }
  }

  /// 내 대기 프로필 스트림
  Stream<CleaningStaff?> getMyWaitingProfileStream(String userId) {
    return _cleaningStaffsRef
        .where('authorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return CleaningStaff.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
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

  /// 청소 전문가의 평점 통계 가져오기
  Future<Map<String, dynamic>> getStaffRatingStats(String staffId) async {
    try {
      // 해당 전문가가 완료한 청소 의뢰 중 리뷰가 있는 것들 가져오기
      final snapshot = await _cleaningRequestsRef
          .where('acceptedApplicantId', isEqualTo: staffId)
          .get();
      
      final reviews = snapshot.docs
          .map((doc) => CleaningRequest.fromFirestore(doc))
          .where((request) => request.review != null)
          .map((request) => request.review!)
          .toList();
      
      if (reviews.isEmpty) {
        return {'averageRating': 0.0, 'reviewCount': 0};
      }
      
      final totalRating = reviews.fold<double>(0.0, (total, review) => total + review.rating);
      final averageRating = totalRating / reviews.length;
      
      return {
        'averageRating': averageRating,
        'reviewCount': reviews.length,
      };
    } catch (e) {
      debugPrint('평점 통계 가져오기 실패: $e');
      return {'averageRating': 0.0, 'reviewCount': 0};
    }
  }

  /// 청소 전문가의 완료된 청소 요청 중 리뷰가 있는 것들 가져오기
  Future<List<CleaningRequest>> getCompletedRequestsWithReviews(String staffId) async {
    try {
      final snapshot = await _cleaningRequestsRef
          .where('acceptedApplicantId', isEqualTo: staffId)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .limit(20)
          .get();
      
      return snapshot.docs
          .map((doc) => CleaningRequest.fromFirestore(doc))
          .where((request) => request.review != null)
          .toList();
    } catch (e) {
      debugPrint('리뷰 가져오기 실패: $e');
      return [];
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _usersRef.doc(user.id).set(user.toFirestore(), SetOptions(merge: true));
  }

  /// 사용자 삭제
  Future<void> deleteUser(String uid) async {
    await _usersRef.doc(uid).delete();
  }
  // ==================== 청소 노하우 관련 메서드 ====================

  CollectionReference get _cleaningKnowhowsRef =>
      _firestore.collection('cleaning_knowhows');

  /// 청소 노하우 생성
  Future<void> createKnowhow(CleaningKnowhow knowhow) async {
    await _cleaningKnowhowsRef.add(knowhow.toFirestore());
  }

  /// 청소 노하우 목록 스트림 (최신순, 최대 50개)
  Stream<List<CleaningKnowhow>> getKnowhows() {
    return _cleaningKnowhowsRef
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CleaningKnowhow.fromFirestore(doc))
          .toList();
    });
  }

  /// 청소 노하우 삭제
  Future<void> deleteKnowhow(String id) async {
    await _cleaningKnowhowsRef.doc(id).delete();
  }

  // ==================== 청소 추천(우리동네청소) 관련 메서드 ====================

  CollectionReference get _cleaningRecommendationsRef =>
      _firestore.collection('cleaning_recommendations');

  /// 청소 추천 생성
  Future<void> createRecommendation(CleaningRecommendation recommendation) async {
    await _cleaningRecommendationsRef.add(recommendation.toFirestore());
  }

  /// 청소 추천 목록 스트림 (최신순, 최대 50개)
  Stream<List<CleaningRecommendation>> getRecommendations() {
    return _cleaningRecommendationsRef
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CleaningRecommendation.fromFirestore(doc))
          .toList();
    });
  }

  /// 청소 추천 삭제
  Future<void> deleteRecommendation(String id) async {
    await _cleaningRecommendationsRef.doc(id).delete();
  }


  /// 토스 페이먼츠 결제 승인 (Cloud Functions 호출)
  Future<Map<String, dynamic>> confirmPayment({
    required String paymentKey,
    required String orderId,
    required int amount,
  }) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('confirmPayment');
      final result = await callable.call({
        'paymentKey': paymentKey,
        'orderId': orderId,
        'amount': amount,
      });

      return {
        'success': true,
        'data': result.data,
      };
    } catch (e) {
      debugPrint('결제 승인 실패 (Cloud Functions): $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

