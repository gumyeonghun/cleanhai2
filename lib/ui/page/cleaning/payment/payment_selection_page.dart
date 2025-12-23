import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cleanhai2/data/model/user_model.dart';
import 'package:tosspayments_widget_sdk_flutter/widgets/agreement.dart';
import 'package:tosspayments_widget_sdk_flutter/widgets/payment_method.dart';
import 'payment_selection_controller.dart';

class PaymentSelectionPage extends StatelessWidget {
  final UserModel applicant;
  final String price;
  final String orderName;
  final String orderId;
  final String customerEmail;

  const PaymentSelectionPage({
    super.key,
    required this.applicant,
    required this.price,
    required this.orderName,
    required this.orderId,
    required this.customerEmail,
  });

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
        backgroundColor: Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '결제 정보',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                             '주문명: $orderName',
                             style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 5),
                            Row(
                              children: [
                                Obx(() => Text(
                                  '결제 금액: ${controller.currentAmount.value}원',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E88E5),
                                  ),
                                )),
                                SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    final textController = TextEditingController(
                                      text: controller.currentAmount.value.toString()
                                    );
                                    Get.defaultDialog(
                                      title: '결제 금액 수정',
                                      content: Column(
                                        children: [
                                          TextField(
                                            controller: textController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: '금액',
                                              suffixText: '원',
                                            ),
                                          ),
                                        ],
                                      ),
                                      textConfirm: '수정',
                                      textCancel: '취소',
                                      confirmTextColor: Colors.white,
                                      onConfirm: () {
                                        final newAmount = int.tryParse(textController.text);
                                        if (newAmount != null && newAmount > 0) {
                                          controller.updateAmount(newAmount);
                                          Get.back();
                                        } else {
                                          Get.snackbar('오류', '올바른 금액을 입력해주세요.');
                                        }
                                      },
                                    );
                                  },
                                  icon: Icon(Icons.edit, color: Colors.grey),
                                  tooltip: '금액 수정',
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // Payment Method Widget with fixed height/container
                    Container(
                      height: 500, // Increased height to ensure content fits
                      color: Colors.transparent, 
                      child: PaymentMethodWidget(
                        paymentWidget: controller.paymentService.paymentWidget,
                        selector: 'methods',
                      ),
                    ),
                    // Agreement Widget
                    SizedBox(
                      height: 50,
                      child: AgreementWidget(
                        paymentWidget: controller.paymentService.paymentWidget,
                        selector: 'agreement',
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                           // Buttons moved here so they also scroll if screen is short
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                controller.processFreeMatching();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                '수수료 무료 매칭',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                controller.processPayment(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1E88E5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                '결제하기',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📋 결제 및 환불 정책 (심사용 · PG 미연동 버전)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                Divider(height: 20),
                                _buildPolicySection(
                                  '1. 결제 안내',
                                  '본 서비스는 현재 서비스 안정화 및 기능 검증을 위한 시범 운영 단계에 있습니다.\n이에 따라 앱 내에서 실제 결제 기능은 제공되지 않으며,\n이용 과정에서 실제 금액이 결제되거나 청구되지 않습니다.\n\n현재 앱 내에 표시되는 금액, 결제 화면, 결제 관련 기능은\n향후 정식 서비스 제공을 위한 기능 테스트 목적으로만 제공됩니다.',
                                ),
                                SizedBox(height: 12),
                                _buildPolicySection(
                                  '2. 서비스 이용 요금',
                                  '• 시범 운영 기간 동안 본 서비스 이용에 따른 실제 결제는 발생하지 않습니다.\n• 서비스 요금은 정식 출시 시점에 별도로 안내될 예정이며,\n요금 정책 변경 시 앱 내 공지 및 약관 개정을 통해 사전 안내합니다.',
                                ),
                                SizedBox(height: 12),
                                _buildPolicySection(
                                  '3. 환불 정책',
                                  '현재 서비스에서는 실제 결제가 이루어지지 않으므로 환불 대상이 발생하지 않습니다.\n\n정식 결제 기능 도입 이후에는:\n• 결제 취소\n• 서비스 미이행\n• 일정 변경 또는 서비스 중단\n\n등의 사유에 따른 환불 정책을 별도로 수립하여\n앱 내 공지사항 및 결제/환불 정책을 통해 안내할 예정입니다.',
                                ),
                                SizedBox(height: 12),
                                _buildPolicySection(
                                  '4. 향후 결제 기능 도입 안내',
                                  '본 서비스는 향후 전자결제대행사(PG)와의 정식 연동을 통해\n앱 내 결제 기능을 제공할 예정입니다.\n\n결제 기능이 도입되는 시점에는:\n• 결제 수단\n• 결제 시점\n• 환불 기준\n• 수수료 정책\n\n등을 명확히 고지하고,\n이용자의 동의를 받은 후 서비스를 제공할 예정입니다.',
                                ),
                                SizedBox(height: 12),
                                _buildPolicySection(
                                  '5. 문의',
                                  '결제 및 서비스 이용과 관련한 문의는\n앱 내 고객센터 또는 문의하기 기능을 통해 접수하실 수 있습니다.',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
