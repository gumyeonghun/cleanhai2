import 'package:flutter/material.dart';
import 'package:tosspayments_widget_sdk_flutter/model/payment_widget_options.dart';
import 'package:tosspayments_widget_sdk_flutter/payment_widget.dart';
import 'package:tosspayments_widget_sdk_flutter/widgets/payment_method.dart';
import 'package:tosspayments_widget_sdk_flutter/widgets/agreement.dart';
import 'package:tosspayments_widget_sdk_flutter/model/payment_info.dart';

class TossPaymentService {
  late PaymentWidget _paymentWidget;
  
  // TODO: Replace with your actual Client Key
  final String _clientKey = 'test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm'; 
  // Customer Key should be unique to the user (e.g. user ID or random UUID)
  final String _customerKey = 'test_customer_key_v2'; 

  TossPaymentService() {
    _paymentWidget = PaymentWidget(
      clientKey: _clientKey,
      customerKey: _customerKey,
    );
  }

  PaymentWidget get paymentWidget => _paymentWidget;

  Future<PaymentMethodWidgetControl?> renderPaymentMethods(
    BuildContext context, {
    required int amount,
  }) async {
    debugPrint('🔵 renderPaymentMethods called with amount: $amount');
    try {
      return await _paymentWidget.renderPaymentMethods(
        selector: 'methods',
        amount: Amount(value: amount, currency: Currency.KRW, country: 'KR'),
        // options: RenderPaymentMethodsOptions(variantKey: 'DEFAULT'), // Removed to use default
      );
    } catch (e) {
      debugPrint('❌ renderPaymentMethods error: $e');
      rethrow;
    }
  }

  Future<AgreementWidgetControl?> renderAgreement(BuildContext context) async {
    debugPrint('🔵 renderAgreement called');
    try {
      return await _paymentWidget.renderAgreement(selector: 'agreement');
    } catch (e) {
      debugPrint('❌ renderAgreement error: $e');
      rethrow;
    }
  }

  Future<dynamic> requestPayment({
    required String orderId,
    required String orderName,
    required int amount,
    required String customerEmail,
    String? customerName,
  }) async {
    debugPrint('🔵 requestPayment called');
    debugPrint('  - orderId: $orderId');
    debugPrint('  - orderName: $orderName');
    debugPrint('  - amount: $amount');
    
    try {
      // Ensure widget is ready. A small delay can help if JS bridge is just finishing up.
      await Future.delayed(Duration(milliseconds: 100)); // Safety delay
      
      final result = await _paymentWidget.requestPayment(
        paymentInfo: PaymentInfo(
          orderId: orderId,
          orderName: orderName,
          customerEmail: customerEmail,
          customerName: customerName,
          appScheme: 'cleanhai2://',
        ),
      );
      debugPrint('✅ requestPayment success result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ requestPayment error: $e');
      rethrow;
    }
  }
}
