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

  // Owner pays for a request (after staff accepted) - TEST VERSION
  Future<void> processPayment() async {
    debugPrint('🔵 processPayment 시작 (테스트 버전)');
    
    if (currentRequest.value == null) {
      debugPrint('❌ currentRequest is null');
      Get.snackbar('오류', '청소 요청 정보를 찾을 수 없습니다.',
        backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    debugPrint('Request ID: ${currentRequest.value!.id}');
    debugPrint('Accepted Applicant ID: ${currentRequest.value?.acceptedApplicantId}');
    
    if (currentRequest.value?.acceptedApplicantId == null) {
      debugPrint('❌ acceptedApplicantId is null');
      Get.snackbar('오류', '수락된 신청자가 없습니다.',
        backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    try {
      // Show loading indicator
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      
      debugPrint('🔍 신청자 프로필 조회 중: ${currentRequest.value!.acceptedApplicantId}');
      final staffProfile = await getUserProfile(currentRequest.value!.acceptedApplicantId!);
      
      // Close loading
      Get.back();
      
      if (staffProfile == null) {
        debugPrint('❌ staffProfile is null');
        Get.snackbar('오류', '신청자 정보를 불러올 수 없습니다.',
          backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      
      debugPrint('✅ 신청자 프로필 조회 성공: ${staffProfile.userName}');
      
      // Validate price
      debugPrint('💰 Price 값 확인: "$price"');
      if (price == null || price!.isEmpty || price == '0' || price == '0원') {
        debugPrint('❌ 유효하지 않은 가격: $price');
        Get.snackbar(
          '오류',
          '청소 금액이 설정되지 않았습니다.\n청소 의뢰를 다시 작성해주세요.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
        return;
      }
      
      // Show test payment confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text('결제 확인 (테스트)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('청소 전문가: ${staffProfile.userName ?? "알 수 없음"}'),
              SizedBox(height: 8),
              Text('청소 금액: ${price ?? "0"}원'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '테스트 모드입니다\n실제 결제는 진행되지 않습니다',
                        style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E88E5),
                foregroundColor: Colors.white,
              ),
              child: Text('결제하기 (테스트)'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        debugPrint('🔵 테스트 결제 진행 중...');
        
        // Show loading
        Get.dialog(
          Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
        
        // Process payment with test data
        final testPaymentKey = 'test_payment_${DateTime.now().millisecondsSinceEpoch}';
        final testOrderId = 'test_order_${DateTime.now().millisecondsSinceEpoch}';
        
        debugPrint('💳 결제 데이터:');
        debugPrint('  - Request ID: ${currentRequest.value!.id}');
        debugPrint('  - Applicant ID: ${currentRequest.value!.acceptedApplicantId}');
        debugPrint('  - Payment Key: $testPaymentKey');
        debugPrint('  - Order ID: $testOrderId');
        
        try {
          debugPrint('🔵 acceptApplicant 호출 중...');
          await _repository.acceptApplicant(
            currentRequest.value!.id,
            currentRequest.value!.acceptedApplicantId!,
            paymentKey: testPaymentKey,
            orderId: testOrderId,
            paymentStatus: 'completed',
          );
          debugPrint('✅ acceptApplicant 완료');

          debugPrint('🔵 청소 상태 업데이트 중...');
          // Update status to 'accepted'
          await _repository.updateCleaningStatus(currentRequest.value!.id, 'accepted');
          debugPrint('✅ 청소 상태 업데이트 완료');

          Get.back(); // Close loading
          
          // Show success message
          Get.snackbar(
            '결제 완료! (테스트)',
            '${staffProfile.userName ?? "청소 전문가"}님과 매칭되었습니다.\n청소 일정을 확인해주세요.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: Duration(seconds: 5),
            snackPosition: SnackPosition.TOP,
            icon: Icon(Icons.check_circle, color: Colors.white),
          );
          
          debugPrint('✅ 테스트 결제 완료');
          await _loadRequestData();
          debugPrint('✅ 데이터 리로드 완료');
        } catch (innerError, stackTrace) {
          debugPrint('❌ 결제 처리 중 내부 에러: $innerError');
          debugPrint('스택 트레이스:\n$stackTrace');
          Get.back(); // Close loading
          Get.snackbar(
            '결제 실패',
            '결제 처리 중 오류가 발생했습니다.\n에러: $innerError',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: Duration(seconds: 5),
          );
          rethrow;
        }
      } else {
        debugPrint('⚠️ 사용자가 결제를 취소함');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ processPayment 오류: $e');
      debugPrint('스택 트레이스:\n$stackTrace');
      // Close loading if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar(
        '오류',
        '결제 처리 중 오류가 발생했습니다.\n에러: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    }
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
