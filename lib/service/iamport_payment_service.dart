import 'package:flutter/material.dart';

/// Simple Payment Service using WebView
/// This is a simplified version for demonstration
class IamportPaymentService {
  /// Process payment with WebView
  Future<Map<String, dynamic>?> processPayment({
    required BuildContext context,
    required String orderId,
    required String orderName,
    required int amount,
    required String customerEmail,
    String? customerName,
  }) async {
    try {
      // For now, return a mock successful payment
      // In production, you would integrate with actual payment gateway
      await Future.delayed(Duration(seconds: 1));
      
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('결제 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('주문명: $orderName'),
              SizedBox(height: 8),
              Text('금액: ${amount.toString().replaceAllMapped(
                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},',
              )}원'),
              SizedBox(height: 16),
              Text(
                '⚠️ 테스트 모드입니다',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
              SizedBox(height: 8),
              Text(
                '실제 결제를 위해서는 아임포트 또는 다른 PG사 연동이 필요합니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, {
                'success': false,
                'error': '결제가 취소되었습니다.',
              }),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'success': true,
                'paymentKey': 'test_payment_${DateTime.now().millisecondsSinceEpoch}',
                'orderId': orderId,
                'message': '테스트 결제가 완료되었습니다.',
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E88E5),
                foregroundColor: Colors.white,
              ),
              child: Text('결제하기 (테스트)'),
            ),
          ],
        ),
      );

      return result;
    } catch (e) {
      debugPrint('Payment error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Verify payment (optional - requires server-side implementation)
  Future<bool> verifyPayment(String paymentKey) async {
    // TODO: Implement server-side payment verification
    return true;
  }
}
