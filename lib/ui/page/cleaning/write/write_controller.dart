import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cleanhai2/data/constants/regions.dart';
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
  
  final RxString selectedCity = ''.obs;
  final RxString selectedDistrict = ''.obs;
  final RxList<String> districts = <String>[].obs;
  final RxString userType = ''.obs;
  final RxString selectedCleaningType = '숙박업소청소'.obs;
  final Rx<DateTime?> selectedCleaningDate = Rx<DateTime?>(null);
  final RxString selectedCleaningDuration = '1일'.obs;

  static const List<String> cleaningDurations = [
    '기타',
    '3개월 이상',
    '1개월',
    '1주일',
    '1일',
  ];

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
      selectedCity.value = ''; // 초기화 로직 필요 시 추가 (주소 파싱 등)
      selectedDistrict.value = '';
      selectedCleaningDuration.value = existingRequest!.cleaningDuration ?? '1일';
    } else if (existingStaff != null) {
      isEditMode.value = true;
      selectedType.value = 'staff';
      titleController.text = existingStaff!.title;
      contentController.text = existingStaff!.content;
      detailAddressController.text = existingStaff!.detailAddress ?? '';
      existingImageUrl.value = existingStaff!.imageUrl ?? '';
      selectedCleaningType.value = existingStaff!.cleaningType ?? '숙박업소청소';
      selectedCity.value = ''; // 초기화 로직 필요 시 추가
      selectedDistrict.value = '';
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

  Future<void> pickCleaningDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedCleaningDate.value ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );

    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedCleaningDate.value ?? DateTime.now()),
      );

      if (pickedTime != null) {
        selectedCleaningDate.value = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
  }

  void updateDistricts(String city) {
    selectedCity.value = city;
    districts.assignAll(Regions.data[city] ?? []);
    selectedDistrict.value = '';
  }

  void updateDistrict(String district) {
    selectedDistrict.value = district;
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
            address: '${selectedCity.value} ${selectedDistrict.value}',
            detailAddress: detailAddressController.text,
            // latitude: null, // Removed
            // longitude: null, // Removed
            updatedAt: now,
            targetStaffId: targetStaffId,
            cleaningType: selectedCleaningType.value,
            requesterName: requesterNameController.text.trim(),
            cleaningToolLocation: cleaningToolLocationController.text.trim(),
            precautions: precautionsController.text.trim(),
            cleaningDate: selectedCleaningDate.value,
            cleaningDuration: selectedCleaningDuration.value,
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
            address: '${selectedCity.value} ${selectedDistrict.value}',
            detailAddress: detailAddressController.text,
            // latitude: null, // Removed
            // longitude: null, // Removed
            createdAt: now,
            updatedAt: now,
            targetStaffId: targetStaffId,
            cleaningType: selectedCleaningType.value,
            requesterName: requesterNameController.text.trim(),
            cleaningToolLocation: cleaningToolLocationController.text.trim(),
            precautions: precautionsController.text.trim(),
            cleaningDate: selectedCleaningDate.value,
            cleaningDuration: selectedCleaningDuration.value,
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
            address: '${selectedCity.value} ${selectedDistrict.value}',
            detailAddress: detailAddressController.text,
            // latitude: null, // Removed
            // longitude: null, // Removed
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
            address: '${selectedCity.value} ${selectedDistrict.value}',
            detailAddress: detailAddressController.text,
            // latitude: null, // Removed
            // longitude: null, // Removed
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
