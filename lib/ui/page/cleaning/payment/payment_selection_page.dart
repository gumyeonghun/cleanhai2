import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cleanhai2/data/model/user_model.dart';
import 'payment_selection_controller.dart';

class PaymentSelectionPage extends StatelessWidget {
  final UserModel applicant;
  final String price;
  final String orderName;
  final String orderId;
  final String customerEmail;

  const PaymentSelectionPage({
    Key? key,
    required this.applicant,
    required this.price,
    required this.orderName,
    required this.orderId,
    required this.customerEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentSelectionController(
      orderId: orderId,
      orderName: orderName,
      price: price,
      customerEmail: customerEmail,
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text('결제하기'),
        backgroundColor: Color(0xFFE53935),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '매칭 대상 확인',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[400],
                      child: Icon(Icons.person, size: 30, color: Colors.white),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            applicant.email, // Or displayName if available
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (applicant.address != null) ...[
                            SizedBox(height: 4),
                            Text(
                              applicant.address!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              Text(
                '결제 금액',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '$price원',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53935),
                ),
              ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    controller.processPayment(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Toss Payments로 결제하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
