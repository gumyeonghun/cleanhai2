import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';
import 'package:cleanhai2/data/model/user_model.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StaffProfileWriteController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  
  final RxBool isLoading = false.obs;
  final Rx<XFile?> selectedImage = Rx<XFile?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  
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
        titleController.text = '청소 가능합니다';
        
        final availabilityStr = '근무 가능: ${currentUser.value!.availableDays?.join(', ') ?? '미설정'}\n시간: ${currentUser.value!.availableStartTime ?? ''} ~ ${currentUser.value!.availableEndTime ?? ''}';
        contentController.text = availabilityStr;
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
        address: user.address,
        latitude: user.latitude,
        longitude: user.longitude,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
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
    super.onClose();
  }
}
