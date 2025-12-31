import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'customer_inquiry_controller.dart';

class CustomerInquiryPage extends StatelessWidget {
  const CustomerInquiryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CustomerInquiryController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '고객문의',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              '궁금한 점이 있으신가요?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '아래 방법 중 편하신 방법으로 문의해주세요.\n최대한 빠르게 답변 드리겠습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 40),
            _buildInquiryButton(
              icon: Icons.email_outlined,
              title: '이메일로 문의하기',
              subtitle: 'myeonghungu1990@daum.net',
              color: Colors.blue,
              onTap: controller.showEmailAddress,
            ),
            SizedBox(height: 20),
            _buildInquiryButton(
              icon: Icons.chat_bubble_outline, // 카카오톡 아이콘 대신 일반 채팅 아이콘 사용 (에셋이 있을 경우 변경)
              title: '카카오톡으로 문의하기',
              subtitle: '평일 09:00 ~ 18:00',
              color: Color(0xFFFEE500), // 카카오 옐로우
              textColor: Colors.black87,
              onTap: controller.openKakaoTalkQuery,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInquiryButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
