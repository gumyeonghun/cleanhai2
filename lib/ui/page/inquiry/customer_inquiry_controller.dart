import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerInquiryController extends GetxController {

  final String supportEmail = 'myeonghungu1990@daum.net';

  // 이메일 주소 보여주기
  void showEmailAddress() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.email_outlined, size: 50, color: Colors.blue),
              SizedBox(height: 16),
              Text(
                '이메일 문의',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SelectableText(
                      supportEmail,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('닫기'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: supportEmail));
                        Get.back();
                        Get.snackbar(
                          '알림', 
                          '이메일 주소가 복사되었습니다.',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: Duration(seconds: 2),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('복사하기', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 카카오톡 문의하기
  Future<void> openKakaoTalkQuery() async {
    // 실제 카카오톡 채널 또는 오픈채팅 URL로 변경 필요
    final Uri kakaoUrl = Uri.parse('http://pf.kakao.com/_xdSyyn');
    
    if (await canLaunchUrl(kakaoUrl)) {
      await launchUrl(kakaoUrl, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('오류', '카카오톡을 실행할 수 없습니다.');
    }
  }


}
