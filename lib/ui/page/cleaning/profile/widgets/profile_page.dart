import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../profile_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('내 프로필', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          Obx(() => TextButton(
            onPressed: () {
              if (controller.isEditing.value) {
                controller.saveProfile();
              } else {
                controller.toggleEditMode();
              }
            },
            child: Text(
              controller.isEditing.value ? '완료' : '수정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE53935),
              ),
            ),
          )),
          SizedBox(width: 16),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        final userModel = controller.userModel.value;

        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              // Profile Image Section
              Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: controller.isEditing.value ? controller.pickImage : null,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(0xFFE53935), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: controller.selectedImage.value != null
                            ? FileImage(controller.selectedImage.value!)
                            : (userModel?.profileImageUrl != null
                                ? NetworkImage(userModel!.profileImageUrl!)
                                : null) as ImageProvider?,
                        child: (controller.selectedImage.value == null && userModel?.profileImageUrl == null)
                            ? Icon(Icons.person, size: 70, color: Colors.grey[300])
                            : null,
                      ),
                    ),
                  ),
                  if (controller.isEditing.value)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: controller.pickImage,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Email (Read-only)
              Text(
                user?.email ?? '로그인 정보 없음',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              SizedBox(height: 10),

              // User Type Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: userModel?.userType == 'staff' 
                      ? Colors.green.withValues(alpha: 0.1) 
                      : Color(0xFFE53935).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  userModel?.userType == 'staff' ? '청소 전문가' : '숙박업소 사장님',
                  style: TextStyle(
                    color: userModel?.userType == 'staff' ? Colors.green[700] : Color(0xFFE53935),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              
              SizedBox(height: 32),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('기본 정보'),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.person_outline,
                            label: '이름',
                            value: userModel?.userName ?? '이름을 입력해주세요',
                            isEditing: controller.isEditing.value,
                            controller: controller.nameController,
                          ),
                          Divider(height: 30),
                          _buildInfoRow(
                            icon: Icons.phone_outlined,
                            label: '전화번호',
                            value: userModel?.phoneNumber ?? '전화번호를 입력해주세요',
                            isEditing: controller.isEditing.value,
                            controller: controller.phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 30),
                    
                    _buildSectionTitle('주소 정보'),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 20),
                              SizedBox(width: 8),
                              Text(
                                '등록된 주소',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            userModel?.address ?? '주소가 등록되지 않았습니다',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: controller.updateAddress,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[50],
                                foregroundColor: Color(0xFFE53935),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Color(0xFFE53935).withValues(alpha: 0.3)),
                                ),
                              ),
                              child: Text(
                                '주소 변경하기',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: controller.logout,
                        icon: Icon(Icons.logout_rounded, size: 20),
                        label: Text('로그아웃'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red[400],
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditing,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[500], size: 22),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 4),
              isEditing
                  ? TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                        hintText: '$label 입력',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: value.contains('입력해주세요') ? Colors.grey[400] : Colors.black87,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
