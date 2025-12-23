import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/model/user_model.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:cleanhai2/ui/page/cleaning/payment/payment_selection_page.dart';
import 'package:flutter/material.dart';

class MyCleaningHistoryController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<CleaningRequest> completedRequests = <CleaningRequest>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      currentUser.value = await _repository.getUserProfile(user.uid);
      _fetchCompletedRequests();
    }
  }

  void _fetchCompletedRequests() {
    final user = currentUser.value;
    if (user == null) return;

    isLoading.value = true;

    // Fetch all requests and filter client-side for simplicity and flexibility
    _repository.getCleaningRequests().listen((requests) {
      final filtered = requests.where((request) {
        // Condition:
        // Show ALL requests where I am involved:
        // 1. I am the Author
        // 2. I am the Accepted Applicant
        // 3. I am the Target Staff (for direct requests)
        
        // Note: effectively changing "Completed Requests" to "My Related Requests"
        
        final isAuthor = request.authorId == user.id;
        final isAcceptedApplicant = request.acceptedApplicantId == user.id;
        final isTargetStaff = request.targetStaffId == user.id;
        
        return isAuthor || isAcceptedApplicant || isTargetStaff;
      }).toList();

      // Sort by latest update or creation
      filtered.sort((a, b) {
        final aTime = a.updatedAt; // Use updatedAt for better "freshness"
        final bTime = b.updatedAt;
        return bTime.compareTo(aTime);
      });

      completedRequests.assignAll(filtered);
      isLoading.value = false;
    });
  }

  Future<void> payForRequest(CleaningRequest request) async {
    if (currentUser.value == null) return;
    if (request.price == null || request.price!.isEmpty) {
      Get.snackbar('오류', '가격 정보가 없습니다.');
      return;
    }

    // 1. 가격 수정/확인 다이얼로그
    String currentPrice = request.price!;
    final priceController = TextEditingController(text: currentPrice);

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('결제 금액 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('결제 전 금액을 수정할 수 있습니다.'),
            SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '결제 금액 (원)',
                border: OutlineInputBorder(),
                suffixText: '원',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text('결제 진행'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    String finalPrice = priceController.text.trim();
    if (finalPrice.isEmpty) return;

    // Generate unique order ID
    final orderId = '${request.id}_${const Uuid().v4().substring(0, 8)}';
    
    // Dummy applicant for constructor (not used in UI)
    final dummyApplicant = UserModel(
      id: request.acceptedApplicantId ?? 'unknown',
      email: '',
      userName: '청소 전문가',
      userType: 'staff',
    );

    final result = await Get.to(() => PaymentSelectionPage(
      applicant: dummyApplicant,
      price: finalPrice, // Use updated price
      orderName: request.title,
      orderId: orderId,
      customerEmail: currentUser.value!.email,
    ));

    if (result != null) {
      if (result['status'] == 'success') {
        isLoading.value = true;
        try {
          final data = result['data'];
          final paymentKey = data.paymentKey;
          final confirmedOrderId = data.orderId;
          final amount = data.amount;

          // Server-side confirmation
          final confirmResult = await _repository.confirmPayment(
            paymentKey: paymentKey,
            orderId: confirmedOrderId,
            amount: int.parse(amount.toString()),
          );

          if (confirmResult['success']) {
             // Save to Firestore with updated price
            await _repository.acceptApplicant(
              request.id,
              request.acceptedApplicantId!,
              paymentKey: paymentKey,
              orderId: confirmedOrderId,
              paymentStatus: 'completed',
              price: finalPrice, // Update the price in DB
            );
            
            await _repository.updateCleaningStatus(request.id, 'in_progress');

            Get.snackbar('성공', '결제가 완료되었습니다.');
            // List will auto-update via stream
          } else {
             Get.snackbar('결제 승인 실패', '결제 승인 중 오류가 발생했습니다: ${confirmResult['error']}');
          }
        } catch (e) {
          debugPrint('Payment Process Error: $e');
           Get.snackbar('오류', '결제 처리 중 오류가 발생했습니다.');
        } finally {
          isLoading.value = false;
        }
      } else if (result['status'] == 'fail') {
         Get.snackbar('결제 실패', '결제가 실패했습니다: ${result['message']}');
      }
    }
  }
}
