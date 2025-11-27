import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kpostal/kpostal.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cleanhai2/data/model/user_model.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';
import '../../auth/login_signup_page.dart';

class ProfileController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Rx<UserModel?> userModel = Rx<UserModel?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isEditing = false.obs; // 편집 모드 상태

  // 텍스트 컨트롤러
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  
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
      }
    }
    isLoading.value = false;
  }

  // 편집 모드 토글
  void toggleEditMode() {
    if (isEditing.value) {
      // 취소 시 원래 값으로 복구
      final user = userModel.value;
      if (user != null) {
        nameController.text = user.userName ?? '';
        phoneController.text = user.phoneNumber ?? '';
        selectedImage.value = null;
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
      );

      await _repository.updateUserProfile(updatedUser);
      userModel.value = updatedUser;
      
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
            userName: user.userName, // 기존 값 유지
            phoneNumber: user.phoneNumber, // 기존 값 유지
            profileImageUrl: user.profileImageUrl, // 기존 값 유지
            userType: user.userType,
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
    Get.offAll(() => LoginSignupPage()); // Navigate to login page and clear all routes
  }
}
