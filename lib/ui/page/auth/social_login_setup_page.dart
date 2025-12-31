import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cleanhai2/data/constants/regions.dart';
import 'auth_controller.dart';

class SocialLoginSetupPage extends StatelessWidget {
  const SocialLoginSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('추가 정보 입력'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '서비스 이용을 위해\n추가 정보를 입력해주세요.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 30),

              // 회원 유형 선택
              Text(
                '회원 유형',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 10),
              Obx(() => Row(
                children: [
                  Expanded(
                    child: _buildRoleButton(
                      title: '청소 의뢰인',
                      value: 'owner',
                      groupValue: controller.userType.value,
                      onTap: () => controller.setUserType('owner'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildRoleButton(
                      title: '청소 전문가',
                      value: 'staff',
                      groupValue: controller.userType.value,
                      onTap: () => controller.setUserType('staff'),
                    ),
                  ),
                ],
              )),
              SizedBox(height: 24),

              // 이름 (이미 소셜에서 가져왔을 수 있지만 확인/수정용)
              // 여기서는 AuthController의 userName 값을 사용하거나 입력 받음
              TextFormField(
                initialValue: controller.userName,
                decoration: _inputDecoration('이름', Icons.person_outline),
                onChanged: (value) => controller.userName = value,
              ),
              SizedBox(height: 16),

              // 전화번호
              TextFormField(
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('전화번호', Icons.phone_outlined),
                onChanged: (value) => controller.phoneNumber = value,
              ),
              SizedBox(height: 16),

              // 생년월일
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(Duration(days: 365 * 20)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    locale: const Locale('ko', 'KR'),
                  );
                  if (picked != null) {
                    controller.setBirthDate(picked);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: Colors.grey[400], size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Obx(() => Text(
                          controller.userBirthDate.value != null
                              ? "${controller.userBirthDate.value!.year}-${controller.userBirthDate.value!.month.toString().padLeft(2, '0')}-${controller.userBirthDate.value!.day.toString().padLeft(2, '0')}"
                              : '생년월일',
                          style: TextStyle(
                            fontSize: 14,
                            color: controller.userBirthDate.value != null ? Colors.black87 : Colors.grey[400],
                          ),
                        )),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // 주소 (지역 선택)
              // Region Selection Dropdowns
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: Obx(() => DropdownButton<String>(
                          value: controller.selectedCity.value.isEmpty ? null : controller.selectedCity.value,
                          hint: Text('시/도', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                          isExpanded: true,
                          items: Regions.data.keys.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.updateDistricts(value);
                            }
                          },
                        )),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Obx(() => Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          key: ValueKey(controller.selectedCity.value), // Force rebuild when city changes
                          value: controller.selectedDistrict.value.isEmpty ? null : controller.selectedDistrict.value,
                          hint: Text('시/구/군', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                          isExpanded: true,
                          items: controller.districts.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.updateDistrict(value);
                            }
                          },
                        ),
                      ),
                    )),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // 상세주소
              TextFormField(
                decoration: _inputDecoration('상세주소 (예: 101호)', Icons.add_location_outlined),
                onChanged: (value) => controller.detailAddress.value = value,
              ),
              SizedBox(height: 40),

              // 완료 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.completeSocialSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E88E5), // Trustworthy Blue
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          '완료',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black, width: 1.5),
      ),
    );
  }

  Widget _buildRoleButton({
    required String title,
    required String value,
    required String groupValue,
    required VoidCallback onTap,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF1E88E5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF1E88E5) : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF1E88E5).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
