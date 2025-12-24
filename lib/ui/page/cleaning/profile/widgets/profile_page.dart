import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../profile_controller.dart';
import 'staff_settlement_page.dart';
import 'owner_payment_history_page.dart';

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
        centerTitle: true,
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
                color: Colors.white,
              ),
            ),
          )),
          SizedBox(width: 16),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
                        border: Border.all(color: Color(0xFF1E88E5), width: 3),
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
                            color: Color(0xFF1E88E5),
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
                      : Color(0xFF1E88E5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  userModel?.userType == 'staff' ? '청소 전문가' : '청소 의뢰인',
                  style: TextStyle(
                    color: userModel?.userType == 'staff' ? Colors.green[700] : Color(0xFF1E88E5),
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
                          Divider(height: 30),
                          _buildDateRow(
                            context: context,
                            icon: Icons.calendar_today_outlined,
                            label: '생년월일',
                            value: controller.birthDate.value != null 
                                ? "${controller.birthDate.value!.year}-${controller.birthDate.value!.month.toString().padLeft(2, '0')}-${controller.birthDate.value!.day.toString().padLeft(2, '0')}"
                                : '생년월일을 입력해주세요',
                            isEditing: controller.isEditing.value,
                            onTap: () => controller.selectBirthDate(context),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 30),
                    
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
                          SizedBox(height: 8),
                          // Detailed Address
                          controller.isEditing.value
                              ? TextField(
                                  controller: controller.detailAddressController,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                    border: InputBorder.none,
                                    hintText: '상세주소 입력 (예: 101호)',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                )
                              : Text(
                                  userModel?.detailAddress ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: controller.updateAddress,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[50],
                                foregroundColor: Color(0xFF1E88E5),
                                elevation: 0,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Color(0xFF1E88E5).withValues(alpha: 0.3)),
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
                    
                    if (userModel?.userType == 'staff') ...[
                      SizedBox(height: 30),
                      _buildSectionTitle('정산 관리'),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
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
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Get.to(() => StaffSettlementPage());
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF1E88E5).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF1E88E5)),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '정산 내역 및 완료 목록',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '완료한 청소와 예상 정산금을 확인하세요',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    if (userModel?.userType == 'owner') ...[
                      SizedBox(height: 30),
                      _buildSectionTitle('지불 관리'),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
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
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Get.to(() => OwnerPaymentHistoryPage());
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF1E88E5).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.payment_outlined, color: Color(0xFF1E88E5)),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '지불 내역 및 완료 목록',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '완료된 청소와 지불한 금액을 확인하세요',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    if (userModel?.userType == 'staff' || userModel?.userType == 'owner') ...[
                      SizedBox(height: 30),
                      _buildSectionTitle(userModel?.userType == 'staff' ? '근무예약설정' : '청소예약설정'),
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
                            Text(
                              userModel?.userType == 'staff' ? '근무 가능 요일' : '청소 필요 요일',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: ['월', '화', '수', '목', '금', '토', '일'].map((day) {
                                return Obx(() {
                                  final isSelected = controller.availableDays.contains(day);
                                  return ChoiceChip(
                                    label: Text(day),
                                    selected: isSelected,
                                    onSelected: controller.isEditing.value 
                                        ? (selected) => controller.toggleDay(day)
                                        : null,
                                    selectedColor: Color(0xFF1E88E5).withValues(alpha: 0.2),
                                    labelStyle: TextStyle(
                                      color: isSelected ? Color(0xFF1E88E5) : Colors.black,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    backgroundColor: Colors.grey[100],
                                  );
                                });
                              }).toList(),
                            ),
                            SizedBox(height: 20),
                            Text(
                              userModel?.userType == 'staff' ? '근무 가능 시간' : '청소 필요 시간',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: controller.isEditing.value 
                                        ? () => controller.selectTime(context, true)
                                        : null,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Obx(() => Text(
                                        controller.startTime.value != null 
                                            ? '${controller.startTime.value!.hour.toString().padLeft(2, '0')}:${controller.startTime.value!.minute.toString().padLeft(2, '0')}'
                                            : '시작 시간',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: controller.startTime.value != null ? Colors.black87 : Colors.grey[400],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text('~', style: TextStyle(color: Colors.grey[400])),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: controller.isEditing.value 
                                        ? () => controller.selectTime(context, false)
                                        : null,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Obx(() => Text(
                                        controller.endTime.value != null 
                                            ? '${controller.endTime.value!.hour.toString().padLeft(2, '0')}:${controller.endTime.value!.minute.toString().padLeft(2, '0')}'
                                            : '종료 시간',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: controller.endTime.value != null ? Colors.black87 : Colors.grey[400],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            if (userModel?.userType == 'owner' || userModel?.userType == 'staff') ...[
                              SizedBox(height: 20),
                              Text(
                                userModel?.userType == 'staff' ? '전문 분야' : '청소 종류',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: controller.isEditing.value ? Colors.grey[50] : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: controller.isEditing.value ? Border.all(color: Colors.grey[200]!) : null,
                                ),
                                child: Obx(() => DropdownButtonFormField<String>(
                                  key: ValueKey(controller.selectedCleaningType.value),
                                  initialValue: controller.selectedCleaningType.value,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: InputBorder.none,
                                    enabled: controller.isEditing.value,
                                  ),
                                  icon: controller.isEditing.value ? Icon(Icons.arrow_drop_down) : SizedBox.shrink(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  items: ProfileController.cleaningTypes.map((String type) {
                                    return DropdownMenuItem<String>(
                                      value: type,
                                      child: Text(type),
                                    );
                                  }).toList(),
                                  onChanged: controller.isEditing.value 
                                      ? (String? newValue) {
                                          if (newValue != null) {
                                            controller.selectedCleaningType.value = newValue;
                                          }
                                        }
                                      : null,
                                )),
                              ),
                              
                              SizedBox(height: 20),
                              Text(
                                '상세 정보 (호실 등)',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                controller: controller.cleaningDetailsController,
                                enabled: controller.isEditing.value,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: '예: 101호, 102호 청소 필요합니다.',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: controller.isEditing.value ? Colors.grey[50] : Colors.transparent,
                                  contentPadding: EdgeInsets.all(16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: controller.isEditing.value ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: controller.isEditing.value ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                                  ),
                                ),
                              ),
                            ],

                            if (userModel?.userType == 'staff') ...[
                              SizedBox(height: 20),
                              Text(
                                '청소 금액',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                controller: controller.cleaningPriceController,
                                enabled: controller.isEditing.value,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '예: 50,000원',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: controller.isEditing.value ? Colors.grey[50] : Colors.transparent,
                                  contentPadding: EdgeInsets.all(16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: controller.isEditing.value ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: controller.isEditing.value ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: 20),
                              Text(
                                '추가옵션 비용',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                controller: controller.additionalOptionCostController,
                                enabled: controller.isEditing.value,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: '예: 창문청소 +10,000원\n베란다청소 +15,000원',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: controller.isEditing.value ? Colors.grey[50] : Colors.transparent,
                                  contentPadding: EdgeInsets.all(16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: controller.isEditing.value ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: controller.isEditing.value ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                                  ),
                                ),
                              ),
                            ],

                            if (userModel?.userType == 'owner') ...[
                              SizedBox(height: 20),
                              Text(
                                '청소도구위치',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                controller: controller.cleaningToolLocationController,
                                enabled: controller.isEditing.value,
                                decoration: InputDecoration(
                                  hintText: '예: 베란다 창고',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: controller.isEditing.value ? Colors.grey[50] : Colors.transparent,
                                  contentPadding: EdgeInsets.all(16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: controller.isEditing.value ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: controller.isEditing.value ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: 20),
                              Text(
                                '청소시 주의사항',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                controller: controller.cleaningPrecautionsController,
                                enabled: controller.isEditing.value,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: '예: 강아지가 있으니 조심해주세요',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: controller.isEditing.value ? Colors.grey[50] : Colors.transparent,
                                  contentPadding: EdgeInsets.all(16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: controller.isEditing.value ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: controller.isEditing.value ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: 20),
                              Text(
                                '청소 금액',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                controller: controller.cleaningPriceController,
                                enabled: controller.isEditing.value,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '예: 50000',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: controller.isEditing.value ? Colors.grey[50] : Colors.transparent,
                                  contentPadding: EdgeInsets.all(16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: controller.isEditing.value ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: controller.isEditing.value ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                                  ),
                                ),
                              ),
                            ],

                            SizedBox(height: 20),
                            Text(
                              '자동 등록 제목',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: controller.autoRegisterTitleController,
                              enabled: controller.isEditing.value,
                              decoration: InputDecoration(
                                hintText: userModel?.userType == 'staff' 
                                    ? '예: 청소 가능합니다' 
                                    : '예: ${userModel?.userName ?? ''}님의 청소 의뢰',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: controller.isEditing.value ? Colors.grey[50] : Colors.transparent,
                                contentPadding: EdgeInsets.all(16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: controller.isEditing.value ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: controller.isEditing.value ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                                ),
                              ),
                            ),

                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  userModel?.userType == 'staff' ? '대기 목록 자동 등록' : '청소 의뢰 자동 등록',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                ),
                                Obx(() => Switch(
                                  value: controller.isAutoRegisterEnabled.value,
                                  onChanged: controller.isEditing.value 
                                      ? (value) => controller.isAutoRegisterEnabled.value = value
                                      : null,
                                  activeThumbColor: Color(0xFF1E88E5),
                                )
                                )],
                            ),

                            if (userModel?.userType == 'owner') ...[
                              SizedBox(height: 20),
                              Text(
                                '청소 현장 사진 (자동 등록용)',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              GestureDetector(
                                onTap: controller.isEditing.value ? controller.pickRequestImage : null,
                                child: Obx(() => Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    image: (controller.selectedRequestImage.value != null || (userModel?.cleaningRequestImageUrl != null && userModel!.cleaningRequestImageUrl!.isNotEmpty))
                                        ? DecorationImage(
                                            image: controller.selectedRequestImage.value != null
                                                ? FileImage(controller.selectedRequestImage.value!)
                                                : NetworkImage(userModel!.cleaningRequestImageUrl!) as ImageProvider,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: (controller.selectedRequestImage.value == null && (userModel?.cleaningRequestImageUrl == null || userModel!.cleaningRequestImageUrl!.isEmpty))
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_a_photo, color: Colors.grey[400], size: 40),
                                              SizedBox(height: 8),
                                              Text(
                                                '사진 추가',
                                                style: TextStyle(color: Colors.grey[400]),
                                              ),
                                            ],
                                          ),
                                        )
                                      : null,
                                )),
                              ),
                            ],
                            
                            // Bump to Top Button removed per user request
                            
                            Text(
                              userModel?.userType == 'staff' 
                                  ? '활성화하면 설정한 시간에 맞춰 대기 목록에 자동으로 노출됩니다.'
                                  : '활성화하면 설정한 내용으로 청소 의뢰가 자동으로 등록됩니다.',
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    if (userModel?.userType == 'staff') ...[
                      SizedBox(height: 30),
                      _buildSectionTitle('청소 후기'),
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
                        child: Obx(() {
                          final stats = controller.staffRatingStats;
                          final reviewsRequests = controller.staffReviewRequests;
                          final averageRating = stats['averageRating'] ?? 0.0;
                          final reviewCount = stats['reviewCount'] ?? 0;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Rating summary
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 32),
                                  SizedBox(width: 8),
                                  Text(
                                    averageRating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '($reviewCount개의 후기)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              
                              if (reviewsRequests.isNotEmpty) ...[
                                SizedBox(height: 20),
                                Divider(),
                                SizedBox(height: 16),
                                
                                // Reviews list
                                ...reviewsRequests.map((request) {
                                  final review = request.review!;
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                ...List.generate(5, (index) {
                                                  return Icon(
                                                    index < review.rating ? Icons.star : Icons.star_border,
                                                    color: Colors.amber,
                                                    size: 16,
                                                  );
                                                }),
                                                SizedBox(width: 8),
                                                Text(
                                                  '${review.createdAt.year}-${review.createdAt.month.toString().padLeft(2, '0')}-${review.createdAt.day.toString().padLeft(2, '0')}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Report Button
                                            PopupMenuButton<String>(
                                              icon: Icon(Icons.more_horiz, size: 20, color: Colors.grey[400]),
                                              onSelected: (value) {
                                                if (value == 'report') {
                                                  // Show Report Dialog
                                                  Get.dialog(
                                                    AlertDialog(
                                                      title: Text('리뷰 신고하기'),
                                                      content: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text('신고 사유를 선택해주세요:'),
                                                          SizedBox(height: 10),
                                                          _buildReportOption(controller, request.id, '부적절한 내용'),
                                                          _buildReportOption(controller, request.id, '스팸/홍보성'),
                                                          _buildReportOption(controller, request.id, '욕설/비방'),
                                                          _buildReportOption(controller, request.id, '기타'),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Get.back(),
                                                          child: Text('취소', style: TextStyle(color: Colors.grey)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
                                              },
                                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                                const PopupMenuItem<String>(
                                                  value: 'report',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.flag_outlined, size: 18, color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('신고하기', style: TextStyle(color: Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          review.comment,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (reviewsRequests.indexOf(request) < reviewsRequests.length - 1)
                                          Padding(
                                            padding: EdgeInsets.only(top: 16),
                                            child: Divider(height: 1),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ] else if (reviewCount == 0) ...[
                                SizedBox(height: 20),
                                Center(
                                  child: Text(
                                    '아직 후기가 없습니다',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        }),
                      ),
                    ],
                    
                    SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (){controller.logout();},
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
                    SizedBox(height: 30),
                    Container(
                      alignment: Alignment.centerRight,
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            controller.deleteAccount();
                          },
                          child: Text(
                            '회원 탈퇴',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                    SizedBox(height: 30),
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

  Widget _buildDateRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required bool isEditing,
    required VoidCallback onTap,
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
              GestureDetector(
                onTap: isEditing ? onTap : null,
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: value.contains('입력해주세요') ? Colors.grey[400] : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildReportOption(ProfileController controller, String requestId, String reason) {
    return InkWell(
      onTap: () {
        Get.back(); // Close dialog
        controller.reportReview(requestId, reason);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(Icons.arrow_right, size: 20, color: Colors.grey),
            SizedBox(width: 8),
            Text(reason, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
