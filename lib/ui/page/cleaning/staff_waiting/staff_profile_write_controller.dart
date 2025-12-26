import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';
import 'package:cleanhai2/data/model/user_model.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import 'package:cleanhai2/data/constants/regions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StaffProfileWriteController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final cleaningPriceController = TextEditingController();
  final additionalOptionCostController = TextEditingController();
  
  final RxBool isLoading = false.obs;
  final Rx<XFile?> selectedImage = Rx<XFile?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxString selectedCleaningType = '숙박업소청소'.obs;
  
  // Availability
  final RxList<String> availableDays = <String>[].obs;
  final Rx<TimeOfDay?> startTime = Rx<TimeOfDay?>(null);
  final Rx<TimeOfDay?> endTime = Rx<TimeOfDay?>(null);
  final RxString selectedCleaningDuration = '1일'.obs; // Default to 1 day as per write controller

  static const List<String> cleaningDurations = [
    '3개월 이상',
    '1개월',
    '1주일',
    '1일',
  ];
  
  // Region Selection
  final RxString selectedCity = ''.obs;
  final RxString selectedDistrict = ''.obs;
  final RxList<String> districts = <String>[].obs;
  
  static const List<String> cleaningTypes = [
    '전체청소',
    '숙박업소청소',
    '사무실청소',
    '건물청소',
    '가게청소',
    '출장손세차',
    '특수청소',
    '입주청소',
    '가정집청소',
    '기타',
  ];
  
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      currentUser.value = await _repository.getUserProfile(user.uid);
      
      // 프로필 정보로 기본값 설정
      if (currentUser.value != null) {
        // Do NOT pre-fill title
        
        // Load pricing from user profile
        cleaningPriceController.text = currentUser.value!.cleaningPrice ?? '';
        additionalOptionCostController.text = currentUser.value!.additionalOptionCost ?? '';
        
        // Load cleaning type from user profile
        selectedCleaningType.value = currentUser.value!.preferredCleaningType ?? '숙박업소청소';

        // Load availability defaults from user profile
        availableDays.assignAll(currentUser.value!.availableDays ?? []);
        if (currentUser.value!.availableStartTime != null) {
          startTime.value = _parseTime(currentUser.value!.availableStartTime!);
        }
        if (currentUser.value!.availableEndTime != null) {
          endTime.value = _parseTime(currentUser.value!.availableEndTime!);
        }
      }
    }
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        selectedImage.value = image;
      }
    } catch (e) {
      Get.snackbar('오류', '이미지를 선택하는 중 오류가 발생했습니다: $e',
        backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<String?> uploadImage() async {
    if (selectedImage.value == null) return null;
    
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('staff_profiles')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await storageRef.putFile(File(selectedImage.value!.path));
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  Future<void> submitProfile() async {
    if (!formKey.currentState!.validate()) return;
    
    final user = currentUser.value;
    if (user == null) {
      Get.snackbar('오류', '사용자 정보를 찾을 수 없습니다.',
        backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (user.userType != 'staff') {
      Get.snackbar('알림', '청소 전문가만 등록할 수 있습니다.',
        backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    
    try {
      // 이미지 업로드
      String? imageUrl;
      if (selectedImage.value != null) {
        imageUrl = await uploadImage();
      } else {
        imageUrl = user.profileImageUrl;
      }
      
      final newStaff = CleaningStaff(
        id: '',
        authorId: user.id,
        authorName: user.userName ?? '이름 없음',
        title: titleController.text.trim(),
        content: contentController.text.trim(),
        imageUrl: imageUrl,
        address: selectedCity.value.isNotEmpty && selectedDistrict.value.isNotEmpty
            ? '${selectedCity.value} ${selectedDistrict.value}'
            : user.address ?? '',
        // latitude: user.latitude, // Removed
        // longitude: user.longitude, // Removed
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        cleaningType: selectedCleaningType.value,
        cleaningPrice: cleaningPriceController.text.trim(),
        additionalOptionCost: additionalOptionCostController.text.trim(),
        availableDays: availableDays.toList(),
        availableStartTime: startTime.value != null ? _formatTime(startTime.value!) : null,
        availableEndTime: endTime.value != null ? _formatTime(endTime.value!) : null,
        cleaningDuration: selectedCleaningDuration.value,
      );

      await _repository.createCleaningStaff(newStaff);
      
      Get.back();
      Get.snackbar('성공', '프로필이 등록되었습니다!',
        backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('오류', '등록 중 오류가 발생했습니다: $e',
        backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    cleaningPriceController.dispose();
    additionalOptionCostController.dispose();
    super.onClose();
  }

  // Helper methods for time/day
  void toggleDay(String day) {
    if (availableDays.contains(day)) {
      availableDays.remove(day);
    } else {
      availableDays.add(day);
    }
  }

  Future<void> selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart 
          ? (startTime.value ?? TimeOfDay(hour: 9, minute: 0))
          : (endTime.value ?? TimeOfDay(hour: 18, minute: 0)),
    );
    if (picked != null) {
      if (isStart) {
        startTime.value = picked;
      } else {
        endTime.value = picked;
      }
    }
  }

  TimeOfDay? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Region selection methods
  void updateDistricts(String city) {
    selectedCity.value = city;
    districts.assignAll(Regions.data[city] ?? []);
    selectedDistrict.value = '';
  }

  void updateDistrict(String district) {
    selectedDistrict.value = district;
  }
}
