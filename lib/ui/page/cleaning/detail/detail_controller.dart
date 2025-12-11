import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import 'package:cleanhai2/data/model/user_model.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';
import 'package:cleanhai2/ui/page/cleaning/payment/payment_selection_page.dart';

class DetailController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  
  // Observables
  final Rx<CleaningRequest?> currentRequest = Rx<CleaningRequest?>(null);
  final Rx<CleaningStaff?> currentStaff = Rx<CleaningStaff?>(null);
  final RxBool isLoading = false.obs;
  final RxString currentUserType = ''.obs;

  // Constructor arguments
  final CleaningRequest? initialRequest;
  final CleaningStaff? initialStaff;

  DetailController({this.initialRequest, this.initialStaff});

  @override
  void onInit() {
    super.onInit();
    currentRequest.value = initialRequest;
    currentStaff.value = initialStaff;
    _loadCurrentUser();
    if (initialRequest != null) {
      _loadRequestData();
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _repository.getUserProfile(user.uid);
      if (userDoc != null) {
        currentUserType.value = userDoc.userType;
      }
    }
  }

  Future<void> _loadRequestData() async {
    if (currentRequest.value != null) {
      final updated = await _repository.getCleaningRequestById(currentRequest.value!.id);
      if (updated != null) {
        currentRequest.value = updated;
      }
    }
  }

  // Getters for UI
  String get title {
    if (currentRequest.value != null) return currentRequest.value!.title;
    if (currentStaff.value != null) return currentStaff.value!.title;
    return '';
  }

  String get content {
    if (currentRequest.value != null) return currentRequest.value!.content;
    if (currentStaff.value != null) return currentStaff.value!.content;
    return '';
  }

  String get authorName {
    if (currentRequest.value != null) return currentRequest.value!.authorName;
    if (currentStaff.value != null) return currentStaff.value!.authorName;
    return '';
  }

  String get authorId {
    if (currentRequest.value != null) return currentRequest.value!.authorId;
    if (currentStaff.value != null) return currentStaff.value!.authorId;
    return '';
  }

  String? get imageUrl {
    if (currentRequest.value != null) return currentRequest.value!.imageUrl;
    if (currentStaff.value != null) return currentStaff.value!.imageUrl;
    return null;
  }

  DateTime get createdAt {
    if (currentRequest.value != null) return currentRequest.value!.createdAt;
    if (currentStaff.value != null) return currentStaff.value!.createdAt;
    return DateTime.now();
  }

  String? get price {
    if (currentRequest.value != null) return currentRequest.value!.price;
    if (currentStaff.value != null) return currentStaff.value!.cleaningPrice;
    return null;
  }

  String? get additionalOptionCost {
    if (currentStaff.value != null) return currentStaff.value!.additionalOptionCost;
    return null;
  }

  String? get cleaningType {
    if (currentRequest.value != null) return currentRequest.value!.cleaningType;
    if (currentStaff.value != null) return currentStaff.value!.cleaningType;
    return null;
  }

  bool get isAuthor {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == authorId;
  }

  bool get hasApplied {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentRequest.value == null) return false;
    return currentRequest.value!.applicants.contains(currentUser.uid);
  }

  // Actions
  Future<void> deleteItem() async {
    if (!isAuthor) {
      Get.snackbar('오류', '삭제 권한이 없습니다');
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('삭제 확인'),
        content: Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (currentRequest.value != null) {
          await _repository.deleteCleaningRequest(currentRequest.value!.id);
        } else if (currentStaff.value != null) {
          await _repository.deleteCleaningStaff(currentStaff.value!.id);
        }
        Get.back(); // Close page
        Get.snackbar('알림', '삭제되었습니다');
      } catch (e) {
        Get.snackbar('오류', '삭제 실패: $e');
      }
    }
  }

  Future<void> applyForJob() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('알림', '로그인이 필요합니다');
      return;
    }

    try {
      await _repository.applyForCleaning(currentRequest.value!.id, user.uid);
      await _loadRequestData();
      Get.snackbar('성공', '청소 신청이 완료되었습니다');
    } catch (e) {
      Get.snackbar('오류', '신청 실패: $e');
    }
  }

  Future<void> acceptApplicant(String applicantId, UserModel? applicantProfile) async {
    if (price == null || price!.isEmpty) {
      Get.snackbar('알림', '청소 금액이 설정되지 않았습니다');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar('알림', '로그인이 필요합니다');
      return;
    }

    if (applicantProfile == null) {
      Get.snackbar('오류', '신청자 정보를 불러올 수 없습니다');
      return;
    }

    final result = await Get.to(() => PaymentSelectionPage(
      applicant: applicantProfile,
      price: price!,
      orderName: title,
      orderId: Uuid().v4(),
      customerEmail: currentUser.email!,
    ));

    if (result != null && result['success'] == true) {
      try {
        Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);
        
        await _repository.acceptApplicant(
          currentRequest.value!.id,
          applicantId,
          paymentKey: result['paymentKey'],
          orderId: result['orderId'],
          paymentStatus: 'completed',
        );

        // Update status to 'accepted'
        await _repository.updateCleaningStatus(currentRequest.value!.id, 'accepted');

        Get.back(); // Close loading
        
        // 의뢰인에게 알림
        Get.snackbar(
          '매칭 완료!',
          '${applicantProfile.userName ?? "청소 전문가"}님과 매칭되었습니다.\n청소 일정을 확인해주세요.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
          snackPosition: SnackPosition.TOP,
          icon: Icon(Icons.check_circle, color: Colors.white),
        );
        
        _loadRequestData();
      } catch (e) {
        Get.back(); // Close loading
        Get.snackbar('오류', '매칭 처리 중 오류가 발생했습니다: $e');
      }
    }
  }

  // Staff accepts a direct request
  Future<void> acceptRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Just set the acceptedApplicantId, payment comes later by owner
      await _repository.acceptApplicant(
        currentRequest.value!.id,
        user.uid,
        paymentStatus: 'pending',
      );
      await _loadRequestData();
      Get.snackbar('수락 완료', '의뢰를 수락했습니다. 의뢰인의 결제를 기다려주세요.');
    } catch (e) {
      Get.snackbar('오류', '수락 실패: $e');
    }
  }

  // Owner pays for a request (after staff accepted)
  Future<void> processPayment() async {
    if (currentRequest.value?.acceptedApplicantId == null) return;
    
    final staffProfile = await getUserProfile(currentRequest.value!.acceptedApplicantId!);
    if (staffProfile == null) return;

    await acceptApplicant(currentRequest.value!.acceptedApplicantId!, staffProfile);
  }

  // Staff starts cleaning
  Future<void> startCleaning() async {
    debugPrint('청소 시작하기 버튼 클릭됨');
    
    if (currentRequest.value == null) {
      Get.snackbar('오류', '청소 요청 정보를 찾을 수 없습니다');
      debugPrint('currentRequest is null');
      return;
    }
    
    debugPrint('Request ID: ${currentRequest.value!.id}');
    debugPrint('Current Status: ${currentRequest.value!.status}');
    
    try {
      await _repository.updateCleaningStatus(currentRequest.value!.id, 'in_progress');
      await _loadRequestData();
      Get.snackbar('청소 시작', '청소가 시작되었습니다. 안전하게 진행해주세요.',
        backgroundColor: Colors.green, colorText: Colors.white);
      debugPrint('청소 상태가 in_progress로 변경됨');
    } catch (e) {
      debugPrint('청소 시작 오류: $e');
      Get.snackbar('오류', '상태 변경 실패: $e',
        backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<UserModel?> getUserProfile(String uid) {
    return _repository.getUserProfile(uid);
  }
}
