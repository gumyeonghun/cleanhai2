import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kpostal/kpostal.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cleanhai2/data/model/user_model.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';
import '../../auth/login_signup_page.dart';

class ProfileController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Rx<UserModel?> userModel = Rx<UserModel?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isEditing = false.obs; // 편집 모드 상태

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cleaningDetailsController = TextEditingController(); // For owners

  // Availability
  final RxList<String> availableDays = <String>[].obs;
  final Rx<TimeOfDay?> startTime = Rx<TimeOfDay?>(null);
  final Rx<TimeOfDay?> endTime = Rx<TimeOfDay?>(null);
  final RxBool isAutoRegisterEnabled = false.obs;

  // 프로필 이미지
  final Rx<File?> selectedImage = Rx<File?>(null);
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }
  
  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    cleaningDetailsController.dispose();
    super.onClose();
  }

  Future<void> loadUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userProfile = await _repository.getUserProfile(user.uid);
      userModel.value = userProfile;
      
      // 초기값 설정
      if (userProfile != null) {
        nameController.text = userProfile.userName ?? '';
        phoneController.text = userProfile.phoneNumber ?? '';
        cleaningDetailsController.text = userProfile.cleaningDetails ?? '';
        
        availableDays.assignAll(userProfile.availableDays ?? []);
        if (userProfile.availableStartTime != null) {
          startTime.value = _parseTime(userProfile.availableStartTime!);
        }
        if (userProfile.availableEndTime != null) {
          endTime.value = _parseTime(userProfile.availableEndTime!);
        }
        isAutoRegisterEnabled.value = userProfile.isAutoRegisterEnabled;
      }
    }
    isLoading.value = false;
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

  // 편집 모드 토글
  void toggleEditMode() {
    if (isEditing.value) {
      // 취소 시 원래 값으로 복구
      final user = userModel.value;
      if (user != null) {
        nameController.text = user.userName ?? '';
        phoneController.text = user.phoneNumber ?? '';
        cleaningDetailsController.text = user.cleaningDetails ?? '';
        selectedImage.value = null;
        
        availableDays.assignAll(user.availableDays ?? []);
        if (user.availableStartTime != null) {
          startTime.value = _parseTime(user.availableStartTime!);
        } else {
          startTime.value = null;
        }
        
        if (user.availableEndTime != null) {
          endTime.value = _parseTime(user.availableEndTime!);
        } else {
          endTime.value = null;
        }
        
        isAutoRegisterEnabled.value = user.isAutoRegisterEnabled;
      }
    }
    isEditing.value = !isEditing.value;
  }

  // 이미지 선택
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage.value = File(image.path);
    }
  }

  // 프로필 저장
  Future<void> saveProfile() async {
    final user = userModel.value;
    if (user == null) return;

    try {
      isLoading.value = true;
      String? imageUrl = user.profileImageUrl;

      // 새 이미지가 선택되었다면 업로드
      if (selectedImage.value != null) {
        imageUrl = await _repository.uploadImage(selectedImage.value!, 'profile');
      }

      final updatedUser = UserModel(
        id: user.id,
        email: user.email,
        address: user.address,
        latitude: user.latitude,
        longitude: user.longitude,
        userType: user.userType,
        userName: nameController.text,
        phoneNumber: phoneController.text,
        profileImageUrl: imageUrl,
        availableDays: availableDays.toList(),
        availableStartTime: startTime.value != null ? _formatTime(startTime.value!) : null,
        availableEndTime: endTime.value != null ? _formatTime(endTime.value!) : null,
        isAutoRegisterEnabled: isAutoRegisterEnabled.value,
        cleaningDetails: cleaningDetailsController.text,
      );

      await _repository.updateUserProfile(updatedUser);
      userModel.value = updatedUser;
      
      // Sync Logic
      if (user.userType == 'staff') {
        // ... (Staff Logic - Unchanged) ...
        if (isAutoRegisterEnabled.value) {
          final existingStaff = await _repository.getCleaningStaffByAuthorId(user.id);
          final availabilityStr = '근무 가능: ${availableDays.join(', ')}\n시간: ${startTime.value != null ? _formatTime(startTime.value!) : ''} ~ ${endTime.value != null ? _formatTime(endTime.value!) : ''}';
          
          if (existingStaff != null) {
            final updatedStaff = existingStaff.copyWith(
              authorName: updatedUser.userName ?? '',
              imageUrl: updatedUser.profileImageUrl,
              address: updatedUser.address,
              latitude: updatedUser.latitude,
              longitude: updatedUser.longitude,
              content: availabilityStr,
              updatedAt: DateTime.now(),
            );
            await _repository.updateCleaningStaff(updatedStaff);
          } else {
            final newStaff = CleaningStaff(
              id: '',
              authorId: user.id,
              authorName: updatedUser.userName ?? '',
              title: '청소 가능합니다',
              content: availabilityStr,
              imageUrl: updatedUser.profileImageUrl,
              address: updatedUser.address,
              latitude: updatedUser.latitude,
              longitude: updatedUser.longitude,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await _repository.createCleaningStaff(newStaff);
          }
        } else {
          await _repository.deleteCleaningStaffByAuthorId(user.id);
        }
      } else if (user.userType == 'owner') {
        // Owner Logic
        if (isAutoRegisterEnabled.value) {
          final existingRequest = await _repository.getCleaningRequestByAuthorId(user.id);
          
          final contentStr = '청소 필요 요일: ${availableDays.join(', ')}\n시간: ${startTime.value != null ? _formatTime(startTime.value!) : ''} ~ ${endTime.value != null ? _formatTime(endTime.value!) : ''}\n상세: ${cleaningDetailsController.text}';
          
          if (existingRequest != null && existingRequest.status == 'pending') {
            // Update existing pending request
            final updatedRequest = existingRequest.copyWith(
              authorName: updatedUser.userName ?? '',
              imageUrl: updatedUser.profileImageUrl,
              address: updatedUser.address,
              latitude: updatedUser.latitude,
              longitude: updatedUser.longitude,
              title: '${updatedUser.userName}님의 청소 의뢰',
              content: contentStr,
              updatedAt: DateTime.now(),
            );
            await _repository.updateCleaningRequest(updatedRequest);
          } else if (existingRequest == null || existingRequest.status != 'pending') {
            // Create new request if no pending request exists
            final newRequest = CleaningRequest(
              id: '',
              authorId: user.id,
              authorName: updatedUser.userName ?? '',
              title: '${updatedUser.userName}님의 청소 의뢰',
              content: contentStr,
              price: '협의', // Default price
              imageUrl: updatedUser.profileImageUrl,
              address: updatedUser.address,
              latitude: updatedUser.latitude,
              longitude: updatedUser.longitude,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              status: 'pending',
            );
            await _repository.createCleaningRequest(newRequest);
          }
        } else {
          // Delete pending request if exists
          await _repository.deleteCleaningRequestByAuthorId(user.id);
        }
      }
      
      isEditing.value = false;
      selectedImage.value = null;
      
      Get.snackbar('성공', '프로필이 업데이트되었습니다',
        backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('오류', '프로필 업데이트 실패: $e',
        backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateAddress() async {
    await Get.to(() => KpostalView(
      callback: (Kpostal result) async {
        double? lat = result.latitude;
        double? lng = result.longitude;

        // 좌표가 없는 경우 주소로 좌표 검색
        if (lat == null || lng == null) {
          try {
            List<Location> locations = await locationFromAddress(result.address);
            if (locations.isNotEmpty) {
              lat = locations.first.latitude;
              lng = locations.first.longitude;
            }
          } catch (e) {
            debugPrint('좌표 변환 실패: $e');
          }
        }

        final user = userModel.value; // 현재 로드된 유저 모델 사용
        if (user != null) {
          final updatedUser = UserModel(
            id: user.id,
            email: user.email,
            address: result.address,
            latitude: lat,
            longitude: lng,
            userName: user.userName,
            phoneNumber: user.phoneNumber,
            profileImageUrl: user.profileImageUrl,
            userType: user.userType,
            availableDays: user.availableDays,
            availableStartTime: user.availableStartTime,
            availableEndTime: user.availableEndTime,
            isAutoRegisterEnabled: user.isAutoRegisterEnabled,
            cleaningDetails: user.cleaningDetails,
          );

          await _repository.updateUserProfile(updatedUser);
          userModel.value = updatedUser;
          
          Get.snackbar('알림', '주소가 업데이트되었습니다');
        }
      },
    ));
  }

  Future<void> logout() async {
    await _auth.signOut();
    Get.offAll(() => LoginSignupPage()); // Navigate to login page after sign out
  }
}
