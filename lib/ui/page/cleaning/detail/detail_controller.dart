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
  final RxBool isLoading = false.obs;
  final Rx<CleaningRequest?> currentRequest = Rx<CleaningRequest?>(null);
  final Rx<CleaningStaff?> currentStaff = Rx<CleaningStaff?>(null);
  final RxString currentUserType = ''.obs;
  final Rx<UserModel?> authorProfile = Rx<UserModel?>(null);
  final RxString existingRequestStatus = ''.obs; // New observable

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
    } else if (initialStaff != null) {
      _checkExistingRequest();
    }
    _loadAuthorProfile();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _repository.getUserProfile(user.uid);
      if (userDoc != null) {
        currentUserType.value = userDoc.userType;
        // Re-check existing request if user type is loaded late (though usually fast)
        if (initialStaff != null) _checkExistingRequest();
      }
    }
  }
  
  void _checkExistingRequest() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && currentStaff.value != null) {
      // Listen to my requests to see if I already requested this staff
      _repository.getAllMyRequestsAsOwner(user.uid).listen((requests) {
        final existing = requests.firstWhereOrNull((req) => 
          req.targetStaffId == currentStaff.value!.authorId && 
          req.status != 'completed'
        );
        if (existing != null) {
          existingRequestStatus.value = existing.status;
        } else {
          existingRequestStatus.value = '';
        }
      });
    }
  }

  Future<void> _loadAuthorProfile() async {
    if (authorId.isNotEmpty) {
      final profile = await _repository.getUserProfile(authorId);
      authorProfile.value = profile;
    }
  }

  Future<void> _loadRequestData() async {
    isLoading.value = true;
    try {
      if (currentRequest.value != null) {
        final updated = await _repository.getCleaningRequestById(currentRequest.value!.id);
        if (updated != null) {
          currentRequest.value = updated;
        }
      }
    } finally {
      isLoading.value = false;
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
        
        // Extract payment info safely
        // Since we treat result['data'] as dynamic, we try to access properties if possible or provide fallback
        // Ideally Toss Widget SDK returns paymentKey/orderId in the success object
        final paymentKey = result['data']?.paymentKey ?? 'toss_payment_${DateTime.now().millisecondsSinceEpoch}';
        final orderId = result['data']?.orderId ?? result['orderId'] ?? Uuid().v4();

        await _repository.acceptApplicant(
          currentRequest.value!.id,
          applicantId,
          paymentKey: paymentKey,
          orderId: orderId,
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
    debugPrint('🔵 processPayment 시작');
    
    if (currentRequest.value == null) {
      Get.snackbar('오류', '청소 요청 정보를 찾을 수 없습니다.',
        backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    if (currentRequest.value?.acceptedApplicantId == null) {
      Get.snackbar('오류', '수락된 신청자가 없습니다.',
        backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar('알림', '로그인이 필요합니다');
      return;
    }
    
    try {
      // Show loading indicator
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      
      final staffProfile = await getUserProfile(currentRequest.value!.acceptedApplicantId!);
      
      // Close loading
      Get.back();
      
      if (staffProfile == null) {
        Get.snackbar('오류', '신청자 정보를 불러올 수 없습니다.',
          backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      
      // Validate price
      if (price == null || price!.isEmpty || price == '0' || price == '0원') {
        Get.snackbar(
          '오류',
          '청소 금액이 설정되지 않았습니다.\n청소 의뢰를 다시 작성해주세요.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
        return;
      }

      // Navigate to Payment Selection Page
      final result = await Get.to(() => PaymentSelectionPage(
        applicant: staffProfile,
        price: price!,
        orderName: title,
        orderId: Uuid().v4(),
        customerEmail: currentUser.email!,
      ));

      if (result != null && result['success'] == true) {
         try {
            Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);
            
            // Handle Free Matching
            if (result['isFree'] == true) {
              debugPrint('🟢 무료 매칭 진행');
              
              // Use a dummy or specific identifier for free matching
              final paymentKey = 'free_match_${Uuid().v4()}';
              final orderId = result['orderId'] ?? Uuid().v4();

              await _repository.acceptApplicant(
                currentRequest.value!.id,
                currentRequest.value!.acceptedApplicantId!,
                paymentKey: paymentKey,
                orderId: orderId,
                paymentStatus: 'completed', // Treat as completed payment
              );

              // Update status to 'accepted'
              await _repository.updateCleaningStatus(currentRequest.value!.id, 'accepted');

              Get.back(); // Close loading
              
              Get.snackbar(
                '매칭 완료!',
                '${staffProfile.userName ?? "청소 전문가"}님과 무료 매칭되었습니다.\n청소 일정을 확인해주세요.',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: Duration(seconds: 5),
                snackPosition: SnackPosition.TOP,
                icon: Icon(Icons.check_circle, color: Colors.white),
              );
              
              await _loadRequestData();
              return;
            }

            // Payment Request Successful (Frontend)
            // Now we MUST confirm it on server side (Cloud Functions)
            debugPrint('🟢 결제 요청 성공, 서버 승인 진행 중...');
            
            // Extract data from result['data'] which is the success object from SDK
            final successData = result['data'];
            final paymentKey = successData.paymentKey;
            final orderId = successData.orderId;
            final amount = successData.amount; // Ensure this is num/int
            
            debugPrint('  - paymentKey: $paymentKey');
            debugPrint('  - orderId: $orderId');
            debugPrint('  - amount: $amount');

            // Call Cloud Function via Repository
            final confirmResult = await _repository.confirmPayment(
              paymentKey: paymentKey,
              orderId: orderId,
              amount: (amount is int) ? amount : (amount as num).toInt(),
            );

            if (confirmResult['success'] == true) {
              debugPrint('✅ 서버 승인 완료!');
              
              // Proceed to update local DB status
              await _repository.acceptApplicant(
                currentRequest.value!.id,
                currentRequest.value!.acceptedApplicantId!,
                paymentKey: paymentKey,
                orderId: orderId,
                paymentStatus: 'completed',
              );

              // Update status to 'accepted'
              await _repository.updateCleaningStatus(currentRequest.value!.id, 'accepted');

              Get.back(); // Close loading
              
              Get.snackbar(
                '결제 완료!',
                '${staffProfile.userName ?? "청소 전문가"}님과 매칭되었습니다.\n청소 일정을 확인해주세요.',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: Duration(seconds: 5),
                snackPosition: SnackPosition.TOP,
                icon: Icon(Icons.check_circle, color: Colors.white),
              );
              
              await _loadRequestData();
            } else {
              // Server confirmation failed
              debugPrint('❌ 서버 승인 실패: ${confirmResult['error']}');
              Get.back(); // Close loading
              Get.snackbar(
                '결제 승인 실패', 
                '결제 요청은 성공했으나 최종 승인에 실패했습니다.\n${confirmResult['error']}',
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: Duration(seconds: 5),
              );
            }
         } catch (e) {
            Get.back(); // Close loading
            Get.snackbar('오류', '결제 처리 중 오류가 발생했습니다: $e');
         }
      }

    } catch (e) {
      debugPrint('❌ processPayment 오류: $e');
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
