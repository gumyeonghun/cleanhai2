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
    // Parse price
    final int amount = int.parse(price.replaceAll(RegExp(r'[^0-9]'), ''));

    final result = await _paymentService.processPayment(
      context: context,
      orderId: orderId,
      orderName: orderName,
      amount: amount,
      customerEmail: customerEmail,
    );

    if (result != null && result['success'] == true) {
      Get.back(result: result); // Return result to previous screen
    } else if (result != null && result['error'] != null) {
      Get.snackbar(
        '결제 실패',
        result['error'],
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
