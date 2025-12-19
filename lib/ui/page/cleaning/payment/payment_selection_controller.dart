import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cleanhai2/service/toss_payment_service.dart';

class PaymentSelectionController extends GetxController {
  final TossPaymentService _paymentService = TossPaymentService();

  // Arguments
  final String orderId;
  final String orderName;
  final String price; // Initial price string
  final String customerEmail;

  // Reactive state
  late final RxInt currentAmount;

  PaymentSelectionController({
    required this.orderId,
    required this.orderName,
    required this.price,
    required this.customerEmail,
  }) {
    // Initialize currentAmount from the price string
    int initialAmount = int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    currentAmount = initialAmount.obs;
  }

  TossPaymentService get paymentService => _paymentService;

  @override
  void onReady() async {
    super.onReady();
    try {
      await _paymentService.renderPaymentMethods(
        Get.context!,
        amount: currentAmount.value,
      );
      await _paymentService.renderAgreement(Get.context!);
    } catch (e) {
      debugPrint('❌ 결제 위젯 렌더링 실패: $e');
      Get.dialog(
        AlertDialog(
          title: Text('오류'),
          content: Text('결제 화면을 불러오는데 실패했습니다.\n다시 시도해주세요.\n(오류: $e)'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> updateAmount(int newAmount) async {
    try {
      currentAmount.value = newAmount;
      await _paymentService.renderPaymentMethods(
        Get.context!,
        amount: newAmount,
      );
    } catch (e) {
      debugPrint('❌ 금액 업데이트 실패: $e');
      Get.snackbar('오류', '금액 업데이트에 실패했습니다.');
    }
  }

  Future<void> processPayment(BuildContext context) async {
    // Test Mode Alert
    Get.dialog(
      AlertDialog(
        title: Text('알림'),
        content: Text('현재는 테스트 버전입니다.\n정식 출시 이후 결제가 가능합니다.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('확인', style: TextStyle(color: Color(0xFF1E88E5))),
          ),
        ],
      ),
    );
    return;

    /*
    try {
      debugPrint('🔵 Toss Payment Requested');
      
      final result = await _paymentService.requestPayment(
        orderId: orderId,
        orderName: orderName,
        amount: currentAmount.value,
        customerEmail: customerEmail,
      );

      debugPrint('결제 결과: $result');

      // The Result object from Toss Payments usually contains 'success' or 'fail'
      dynamic dynamicResult = result;

      if (dynamicResult.success != null) {
        // Success case
        Get.back(result: {'success': true, 'data': dynamicResult.success});
      } else if (dynamicResult.fail != null) {
        // Fail case
        debugPrint('결제 실패: ${dynamicResult.fail}');
        String errorMessage = dynamicResult.fail.errorMessage ?? '결제에 실패했습니다.';
        String errorCode = dynamicResult.fail.errorCode ?? '';

        if (errorCode == 'NOT_SELECTED_PAYMENT_METHOD') {
          errorMessage = '결제 수단을 선택해주세요.';
        }

        Get.snackbar(
          '결제 실패',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // Unknown state, but assume failure or cancellation if success is null
        Get.snackbar(
          '알림',
          '결제가 완료되지 않았습니다.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('❌ processPayment 오류: $e');
      Get.snackbar(
        '오류',
        '결제 처리 중 오류가 발생했습니다: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    */
  }

  void processFreeMatching() {
    Get.back(result: {'success': true, 'isFree': true});
  }
}
