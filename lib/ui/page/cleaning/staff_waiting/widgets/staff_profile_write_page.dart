import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../staff_profile_write_controller.dart';

class StaffProfileWritePage extends StatelessWidget {
  const StaffProfileWritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StaffProfileWriteController());

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            '청소 전문가 프로필 등록',
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
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 안내 메시지
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E88E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF1E88E5).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF1E88E5)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '청소 대기 목록에 등록할 프로필을 작성해주세요.',
                          style: TextStyle(
                            color: Color(0xFF1E88E5),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // 프로필 이미지
                Text(
                  '프로필 사진',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: controller.pickImage,
                    child: Obx(() {
                      return Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                        ),
                        child: controller.selectedImage.value != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(controller.selectedImage.value!.path),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : controller.currentUser.value?.profileImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      controller.currentUser.value!.profileImageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[400]),
                                      SizedBox(height: 8),
                                      Text(
                                        '사진 추가',
                                        style: TextStyle(color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 24),

                // 제목
                Text(
                  '제목',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: controller.titleController,
                  decoration: InputDecoration(
                    hintText: '예: 청소 가능합니다',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF1E88E5), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '제목을 입력해주세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // 소개 내용
                Text(
                  '소개 내용',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: controller.contentController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: '근무 가능 시간, 경력, 특기 등을 작성해주세요.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF1E88E5), width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '소개 내용을 입력해주세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // 전문 분야
                Text(
                  '전문 분야',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Obx(() => Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: controller.selectedCleaningType.value,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                    ),
                    icon: Icon(Icons.arrow_drop_down, color: Color(0xFF1E88E5)),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    items: StaffProfileWriteController.cleaningTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        controller.selectedCleaningType.value = newValue;
                      }
                    },
                  ),
                )),
                SizedBox(height: 24),

                // 주소 정보 (읽기 전용)
                Obx(() {
                  final user = controller.currentUser.value;
                  if (user?.address != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '활동 지역',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Color(0xFF1E88E5)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  user!.address!,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '* 프로필 페이지에서 주소를 변경할 수 있습니다.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 24),
                      ],
                    );
                  }
                  return SizedBox.shrink();
                }),

                // 청소 금액
                Text(
                  '청소 금액',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: controller.cleaningPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '예: 50,000원',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF1E88E5), width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // 추가옵션 비용
                Text(
                  '추가옵션 비용',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: controller.additionalOptionCostController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '예: 창문청소 +10,000원\n베란다청소 +15,000원',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF1E88E5), width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // 등록 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.submitProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            '등록하기',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  )),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
