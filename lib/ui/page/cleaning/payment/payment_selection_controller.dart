import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cleanhai2/service/iamport_payment_service.dart';

class PaymentSelectionController extends GetxController {
  final IamportPaymentService _paymentService = IamportPaymentService();

  // Arguments
  final String orderId;
  final String orderName;
  final String price;
  final String customerEmail;

  PaymentSelectionController({
    required this.orderId,
    required this.orderName,
    required this.price,
    required this.customerEmail,
  });

  Future<void> processPayment(BuildContext context) async {
    try {
      debugPrint('🔵 PaymentSelectionController.processPayment 시작');
      debugPrint('Order ID: $orderId');
      debugPrint('Order Name: $orderName');
      debugPrint('Price: $price');
      debugPrint('Customer Email: $customerEmail');
      
      // Parse price
      final int amount = int.parse(price.replaceAll(RegExp(r'[^0-9]'), ''));
      debugPrint('Parsed amount: $amount');

      debugPrint('🔵 결제 서비스 호출 중...');
      final result = await _paymentService.processPayment(
        context: context,
        orderId: orderId,
        orderName: orderName,
        amount: amount,
        customerEmail: customerEmail,
      );

      debugPrint('결제 결과: $result');

      if (result != null && result['success'] == true) {
        debugPrint('✅ 결제 성공');
        Get.back(result: result); // Return result to previous screen
      } else if (result != null && result['error'] != null) {
        debugPrint('❌ 결제 실패: ${result['error']}');
        Get.snackbar(
          '결제 실패',
          result['error'],
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        debugPrint('⚠️ 결제 결과가 null이거나 예상치 못한 형식');
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
  }
}
