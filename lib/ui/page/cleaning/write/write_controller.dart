import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kpostal/kpostal.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';

class WriteController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final ImagePicker _picker = ImagePicker();

  // Form Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController detailAddressController = TextEditingController();
  final TextEditingController requesterNameController = TextEditingController();
  final TextEditingController cleaningToolLocationController = TextEditingController();
  final TextEditingController precautionsController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Observables
  final RxString selectedType = 'request'.obs;
  final Rx<File?> imageFile = Rx<File?>(null);
  final RxString existingImageUrl = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isEditMode = false.obs;
  
  final RxString address = ''.obs;
  final RxDouble latitude = 0.0.obs;
  final RxDouble longitude = 0.0.obs;
  final RxString userType = ''.obs;
  final RxString selectedCleaningType = '숙박업소청소'.obs;

  static const List<String> cleaningTypes = [
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

  // Constructor arguments
  final String? initialType;
  final CleaningRequest? existingRequest;
  final CleaningStaff? existingStaff;
  final String? targetStaffId; // For direct requests

  WriteController({
    this.initialType,
    this.existingRequest,
    this.existingStaff,
    this.targetStaffId,
  });

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    priceController.dispose();
    detailAddressController.dispose();
    requesterNameController.dispose();
    cleaningToolLocationController.dispose();
    precautionsController.dispose();
    super.onClose();
  }

  void _initializeData() {
    if (initialType != null) {
      selectedType.value = initialType!;
    }

    if (existingRequest != null) {
      isEditMode.value = true;
      selectedType.value = 'request';
      titleController.text = existingRequest!.title;
      contentController.text = existingRequest!.content;
      priceController.text = existingRequest!.price ?? '';
      detailAddressController.text = existingRequest!.detailAddress ?? '';
      existingImageUrl.value = existingRequest!.imageUrl ?? '';
      address.value = existingRequest!.address ?? '';
      latitude.value = existingRequest!.latitude ?? 0.0;
      longitude.value = existingRequest!.longitude ?? 0.0;
      selectedCleaningType.value = existingRequest!.cleaningType ?? '숙박업소청소';
      requesterNameController.text = existingRequest!.requesterName ?? '';
      cleaningToolLocationController.text = existingRequest!.cleaningToolLocation ?? '';
      precautionsController.text = existingRequest!.precautions ?? '';
    } else if (existingStaff != null) {
      isEditMode.value = true;
      selectedType.value = 'staff';
      titleController.text = existingStaff!.title;
      contentController.text = existingStaff!.content;
      detailAddressController.text = existingStaff!.detailAddress ?? '';
      existingImageUrl.value = existingStaff!.imageUrl ?? '';
      address.value = existingStaff!.address ?? '';
      latitude.value = existingStaff!.latitude ?? 0.0;
      longitude.value = existingStaff!.longitude ?? 0.0;
      selectedCleaningType.value = existingStaff!.cleaningType ?? '숙박업소청소';
    }

    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userProfile = await _repository.getUserProfile(user.uid);
      if (userProfile != null) {
        userType.value = userProfile.userType;
        // Set default type based on user role if not in edit mode AND initialType is not provided
        if (!isEditMode.value && initialType == null) {
          if (userType.value == 'owner') {
            selectedType.value = 'request';
          } else if (userType.value == 'staff') {
            selectedType.value = 'staff';
          }
        }
      }
    }
  }

  void setType(String type) {
    selectedType.value = type;
  }

  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        imageFile.value = File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar('오류', '이미지 선택 실패: $e');
    }
  }

  Future<void> searchAddress() async {
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

        address.value = result.address;
        latitude.value = lat ?? 0.0;
        longitude.value = lng ?? 0.0;
      },
    ));
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    isLoading.value = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 수정 권한 확인
      if (isEditMode.value) {
        if (existingRequest != null && existingRequest!.authorId != user.uid) {
          throw Exception('수정 권한이 없습니다');
        }
        if (existingStaff != null && existingStaff!.authorId != user.uid) {
          throw Exception('수정 권한이 없습니다');
        }
      }

      String? imageUrl = existingImageUrl.value.isEmpty ? null : existingImageUrl.value;

      // 새 이미지가 선택된 경우 업로드
      if (imageFile.value != null) {
        imageUrl = await _repository.uploadImage(imageFile.value!, selectedType.value);
        
        // 기존 이미지가 있었다면 삭제
        if (existingImageUrl.value.isNotEmpty) {
          await _repository.deleteImage(existingImageUrl.value);
        }
      }

      final now = DateTime.now();

      if (selectedType.value == 'request') {
        if (isEditMode.value && existingRequest != null) {
          // 청소 의뢰 수정
          final updatedRequest = existingRequest!.copyWith(
            title: titleController.text.trim(),
            content: contentController.text.trim(),
            price: priceController.text.trim(),
            imageUrl: imageUrl,
            address: address.value.isEmpty ? null : address.value,
            detailAddress: detailAddressController.text,
            latitude: latitude.value == 0.0 ? null : latitude.value,
            longitude: longitude.value == 0.0 ? null : longitude.value,
            updatedAt: now,
            targetStaffId: targetStaffId,
            cleaningType: selectedCleaningType.value,
            requesterName: requesterNameController.text.trim(),
            cleaningToolLocation: cleaningToolLocationController.text.trim(),
            precautions: precautionsController.text.trim(),
          );
          await _repository.updateCleaningRequest(updatedRequest);
        } else {
          // 청소 의뢰 생성
          final request = CleaningRequest(
            id: '',
            authorId: user.uid,
            authorName: user.email ?? '익명',
            title: titleController.text.trim(),
            content: contentController.text.trim(),
            price: priceController.text.trim(),
            imageUrl: imageUrl,
            address: address.value.isEmpty ? null : address.value,
            detailAddress: detailAddressController.text,
            latitude: latitude.value == 0.0 ? null : latitude.value,
            longitude: longitude.value == 0.0 ? null : longitude.value,
            createdAt: now,
            updatedAt: now,
            targetStaffId: targetStaffId,
            cleaningType: selectedCleaningType.value,
            requesterName: requesterNameController.text.trim(),
            cleaningToolLocation: cleaningToolLocationController.text.trim(),
            precautions: precautionsController.text.trim(),
          );
          await _repository.createCleaningRequest(request);
        }
      } else {
        if (isEditMode.value && existingStaff != null) {
          // 청소 대기 수정
          final updatedStaff = existingStaff!.copyWith(
            title: titleController.text.trim(),
            content: contentController.text.trim(),
            imageUrl: imageUrl,
            address: address.value.isEmpty ? null : address.value,
            detailAddress: detailAddressController.text,
            latitude: latitude.value == 0.0 ? null : latitude.value,
            longitude: longitude.value == 0.0 ? null : longitude.value,
            updatedAt: now,
            cleaningType: selectedCleaningType.value,
          );
          await _repository.updateCleaningStaff(updatedStaff);
        } else {
          // 청소 대기 생성
          final staff = CleaningStaff(
            id: '',
            authorId: user.uid,
            authorName: user.email ?? '익명',
            title: titleController.text.trim(),
            content: contentController.text.trim(),
            imageUrl: imageUrl,
            address: address.value.isEmpty ? null : address.value,
            detailAddress: detailAddressController.text,
            latitude: latitude.value == 0.0 ? null : latitude.value,
            longitude: longitude.value == 0.0 ? null : longitude.value,
            createdAt: now,
            updatedAt: now,
            cleaningType: selectedCleaningType.value,
          );
          await _repository.createCleaningStaff(staff);
        }
      }

      Get.back();
      Get.snackbar('알림', isEditMode.value ? '수정되었습니다' : '등록되었습니다');
    } catch (e) {
      Get.snackbar('오류', '오류 발생: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
