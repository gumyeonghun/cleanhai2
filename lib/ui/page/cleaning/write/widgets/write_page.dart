import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import 'package:cleanhai2/data/constants/regions.dart'; // Import Regions
import '../write_controller.dart';

class WritePage extends StatelessWidget {
  final String? type; // 'request' or 'staff'
  final CleaningRequest? existingRequest;
  final CleaningStaff? existingStaff;
  final String? targetStaffId; // For direct requests

  const WritePage({
    super.key,
    this.type,
    this.existingRequest,
    this.existingStaff,
    this.targetStaffId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WriteController(
      initialType: type,
      existingRequest: existingRequest,
      existingStaff: existingStaff,
      targetStaffId: targetStaffId,
    ));

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Obx(() => Text(
            controller.isEditMode.value ? '수정하기' : '글쓰기',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          )),
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
          actions: [
            GestureDetector(
              onTap: () {
                if (!controller.isLoading.value) {
                  controller.submit();
                }
              },
              child: Container(
                margin: EdgeInsets.only(right: 16),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Obx(() => controller.isLoading.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        '완료',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
              ),
            ),
          ],
        ),
        body: Form(
          key: controller.formKey,
          child: ListView(
            padding: EdgeInsets.all(24),
            children: [
              // 타입 선택 (수정 모드가 아닐 때만)
              Obx(() {
                if (!controller.isEditMode.value && controller.userType.value.isEmpty) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => controller.setType('request'),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: controller.selectedType.value == 'request'
                                    ? Color(0xFF1E88E5)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '청소 의뢰',
                                style: TextStyle(
                                  color: controller.selectedType.value == 'request'
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => controller.setType('staff'),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: controller.selectedType.value == 'staff'
                                    ? Color(0xFF1E88E5)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '청소 대기',
                                style: TextStyle(
                                  color: controller.selectedType.value == 'staff'
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              }),
              
              // 청소 종류 선택 (청소 의뢰 또는 청소 대기일 때)
              Obx(() {
                if (controller.selectedType.value == 'request' || controller.selectedType.value == 'staff') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.selectedType.value == 'staff' ? '전문 분야' : '청소 종류',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: controller.selectedCleaningType.value,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: InputBorder.none,
                          ),
                          items: WriteController.cleaningTypes.map((String type) {
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '청소 종류를 선택해 주세요';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  );
                }
                return SizedBox.shrink();
              }),
              
              // 제목
              Text(
                '제목',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Obx(() => TextFormField(
                controller: controller.titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: controller.selectedType.value == 'request' ? '예: 호텔입니다' : '예: 20년차 가정주부입니다',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    borderSide: BorderSide(color: Color(0xFF1E88E5)),
                  ),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return '제목을 입력해 주세요';
                  }
                  return null;
                },
              )),
              
              SizedBox(height: 24),

              // 청소 의뢰인 이름 (청소 의뢰일 때만)
              Obx(() {
                if (controller.selectedType.value == 'request') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '청소 의뢰인 이름',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: controller.requesterNameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: '예: 홍길동',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            borderSide: BorderSide(color: Color(0xFF1E88E5)),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  );
                }
                return SizedBox.shrink();
              }),

              // 금액 (청소 의뢰일 때만)
              Obx(() {
                if (controller.selectedType.value == 'request') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '청소 금액',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: controller.priceController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: '예: 50000',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            borderSide: BorderSide(color: Color(0xFF1E88E5)),
                          ),
                          suffixText: '원',
                        ),
                        validator: (value) {
                          if (controller.selectedType.value == 'request' && (value?.trim().isEmpty ?? true)) {
                            return '금액을 입력해 주세요';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24),
                    ],
                  );
                }
                return SizedBox.shrink();
              }),

              // 청소 날짜 및 시간 (청소 의뢰일 때만)
              Obx(() {
                if (controller.selectedType.value == 'request') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '청소 필요 날짜 및 시간',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => controller.pickCleaningDate(context),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Obx(() => Icon(
                                Icons.calendar_today,
                                color: controller.selectedCleaningDate.value != null
                                    ? Color(0xFF1E88E5)
                                    : Colors.grey[400],
                              )),
                              SizedBox(width: 12),
                              Expanded(
                                child: Obx(() {
                                  final date = controller.selectedCleaningDate.value;
                                  return Text(
                                    date != null
                                        ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                                        : '날짜 및 시간 선택 (선택사항)',
                                    style: TextStyle(
                                      color: date != null ? Colors.black87 : Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                  );
                                }),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  );
                }
                return SizedBox.shrink();
              }),

              // 청소 필요 기간 (청소 의뢰일 때만)
              Obx(() {
                if (controller.selectedType.value == 'request') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '청소 필요 기간',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: controller.selectedCleaningDuration.value,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: InputBorder.none,
                          ),
                          items: WriteController.cleaningDurations.map((String duration) {
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
                      SizedBox(height: 24),
                    ],
                  );
                }
                return SizedBox.shrink();
              }),
              
              // 내용
              Text(
                '내용',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: Obx(() => TextFormField(
                  controller: controller.contentController,
                  maxLines: null,
                  expands: true,
                  textInputAction: TextInputAction.newline,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: controller.selectedType.value == 'request'
                        ? '예: 5시부터 3개호실 청소 부탁드립니다'
                        : '예: 어떤 청소든지 자신있습니다',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.all(16),
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
                      borderSide: BorderSide(color: Color(0xFF1E88E5)),
                    ),
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return '내용을 입력해 주세요';
                    }
                    return null;
                  },
                )),
              ),
              
              SizedBox(height: 24),

              // 청소 도구 위치 및 주의사항 (청소 의뢰일 때만)
              Obx(() {
                if (controller.selectedType.value == 'request') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '청소 도구 위치',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: controller.cleaningToolLocationController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: '예: 베란다 창고',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            borderSide: BorderSide(color: Color(0xFF1E88E5)),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      Text(
                        '청소시 주의사항',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: controller.precautionsController,
                        textInputAction: TextInputAction.done,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: '예: 강아지가 있으니 조심해주세요',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            borderSide: BorderSide(color: Color(0xFF1E88E5)),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  );
                }
                return SizedBox.shrink();
              }),

              // 주소 선택
              Text(
                '위치',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: '시/도',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                        ),
                        items: Regions.data.keys.map((String city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Text(city),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.updateDistricts(value);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '시/도를 선택해주세요';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(controller.selectedCity.value),
                            decoration: InputDecoration(
                              hintText: '시/구/군',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: InputBorder.none,
                            ),
                            items: controller.districts.map((String district) {
                              return DropdownMenuItem<String>(
                                value: district,
                                child: Text(district),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                controller.updateDistrict(value);
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '시/구/군을 선택해주세요';
                              }
                              return null;
                            },
                          ),
                        )),
                  ),
                ],
              ),

              SizedBox(height: 8),
              TextFormField(
                controller: controller.detailAddressController,
                decoration: InputDecoration(
                  hintText: '상세주소 (예: 101동 101호)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    borderSide: BorderSide(color: Color(0xFF1E88E5)),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // 이미지 선택
              Text(
                '사진',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: controller.pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Obx(() {
                    if (controller.imageFile.value != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          controller.imageFile.value!,
                          fit: BoxFit.cover,
                        ),
                      );
                    } else if (controller.existingImageUrl.value.isNotEmpty) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          controller.existingImageUrl.value,
                          fit: BoxFit.cover,
                        ),
                      );
                    } else {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[400]),
                          SizedBox(height: 12),
                          Text(
                            '사진 추가하기',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    }
                  }),
                ),
              ),
              
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
