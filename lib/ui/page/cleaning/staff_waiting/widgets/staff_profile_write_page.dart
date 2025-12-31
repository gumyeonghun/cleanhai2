import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:cleanhai2/data/constants/regions.dart';
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
                  '청소종류',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Obx(() => Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedCleaningType.value,
                        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF1E88E5)),
                        isExpanded: true,
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
                    ),
                  ),
                )),
                SizedBox(height: 24),

                // 활동 지역 선택 (기존 주소 표시 대체)
                Text(
                  '활동 지역',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
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
                            key: ValueKey(controller.selectedCity.value),
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
                SizedBox(height: 24),
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
                    hintStyle: TextStyle(color: Colors.grey[400]),
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
                    hintStyle: TextStyle(color: Colors.grey[400]),
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

                // 근무 가능 기간
                Text(
                  '근무 가능 기간',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Obx(() => Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedCleaningDuration.value,
                        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF1E88E5)),
                        isExpanded: true,
                        items: StaffProfileWriteController.cleaningDurations.map((String duration) {
                          return DropdownMenuItem<String>(
                            value: duration,
                            child: Text(duration),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            controller.selectedCleaningDuration.value = newValue;
                          }
                        },
                      ),
                    ),
                  ),
                )),
                SizedBox(height: 24),

                // 근무 가능 요일
                Text(
                  '근무 가능 요일',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['월', '화', '수', '목', '금', '토', '일'].map((day) {
                    final isSelected = controller.availableDays.contains(day);
                    return ChoiceChip(
                      label: Text(day),
                      selected: isSelected,
                      onSelected: (_) => controller.toggleDay(day),
                      selectedColor: Color(0xFF1E88E5),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Color(0xFF1E88E5) : Colors.grey[300]!,
                        ),
                      ),
                    );
                  }).toList(),
                )),
                SizedBox(height: 24),

                // 근무 가능 시간
                Text(
                  '근무 가능 시간',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.selectTime(context, true),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('시작 시간', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              SizedBox(height: 4),
                              Obx(() => Text(
                                controller.startTime.value != null
                                    ? controller.startTime.value!.format(context)
                                    : '선택',
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold,
                                  color: controller.startTime.value != null ? Colors.black87 : Colors.grey[400],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('~', style: TextStyle(fontSize: 20, color: Colors.grey[400])),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.selectTime(context, false),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('종료 시간', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              SizedBox(height: 4),
                              Obx(() => Text(
                                controller.endTime.value != null
                                    ? controller.endTime.value!.format(context)
                                    : '선택',
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold,
                                  color: controller.endTime.value != null ? Colors.black87 : Colors.grey[400],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
