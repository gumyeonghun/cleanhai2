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
import 'package:cleanhai2/data/model/review.dart';
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
  final TextEditingController addressController = TextEditingController();
  final TextEditingController detailAddressController = TextEditingController();
  final TextEditingController cleaningDetailsController = TextEditingController(); // For owners
  final TextEditingController cleaningToolLocationController = TextEditingController(); // For owners
  final TextEditingController cleaningPrecautionsController = TextEditingController(); // For owners
  final TextEditingController cleaningPriceController = TextEditingController(); // For staff
  final TextEditingController additionalOptionCostController = TextEditingController(); // For staff
  final TextEditingController autoRegisterTitleController = TextEditingController(); // For auto-registration title
  final Rx<DateTime?> birthDate = Rx<DateTime?>(null);

  // Availability
  final RxList<String> availableDays = <String>[].obs;
  final Rx<TimeOfDay?> startTime = Rx<TimeOfDay?>(null);
  final Rx<TimeOfDay?> endTime = Rx<TimeOfDay?>(null);
  final RxBool isAutoRegisterEnabled = false.obs;
  
  // Cleaning Type
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

  // 프로필 이미지
  final Rx<File?> selectedImage = Rx<File?>(null);
  final ImagePicker _picker = ImagePicker();

  // Staff reviews and ratings
  final RxMap<String, dynamic> staffRatingStats = <String, dynamic>{}.obs;
  final RxList<Review> staffReviews = <Review>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }
  
  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    detailAddressController.dispose();
    cleaningDetailsController.dispose();
    cleaningToolLocationController.dispose();
    cleaningPrecautionsController.dispose();
    cleaningPriceController.dispose();
    additionalOptionCostController.dispose();
    autoRegisterTitleController.dispose();
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
        addressController.text = userProfile.address ?? '';
        detailAddressController.text = userProfile.detailAddress ?? '';
        cleaningDetailsController.text = userProfile.cleaningDetails ?? '';
        cleaningToolLocationController.text = userProfile.cleaningToolLocation ?? '';
        cleaningPrecautionsController.text = userProfile.cleaningPrecautions ?? '';
        cleaningPriceController.text = userProfile.cleaningPrice ?? '';
        additionalOptionCostController.text = userProfile.additionalOptionCost ?? '';
        autoRegisterTitleController.text = userProfile.autoRegisterTitle ?? '';
        birthDate.value = userProfile.birthDate;
        
        availableDays.assignAll(userProfile.availableDays ?? []);
        if (userProfile.availableStartTime != null) {
          startTime.value = _parseTime(userProfile.availableStartTime!);
        }
        if (userProfile.availableEndTime != null) {
          endTime.value = _parseTime(userProfile.availableEndTime!);
        }

        isAutoRegisterEnabled.value = userProfile.isAutoRegisterEnabled;
        selectedCleaningType.value = userProfile.preferredCleaningType ?? '숙박업소청소';
        
        // Load staff reviews if user is staff
        if (userProfile.userType == 'staff') {
          loadStaffReviews();
        }
      }
    }
    isLoading.value = false;
  }

  Future<void> loadStaffReviews() async {
    final user = userModel.value;
    if (user != null && user.userType == 'staff') {
      try {
        // Get rating stats
        final stats = await _repository.getStaffRatingStats(user.id);
        staffRatingStats.value = stats;
        
        // Get all completed requests with reviews
        final requests = await _repository.getCompletedRequestsWithReviews(user.id);
        staffReviews.assignAll(requests.map((r) => r.review!).toList());
      } catch (e) {
        debugPrint('Failed to load staff reviews: $e');
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

  Future<void> selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthDate.value ?? DateTime.now().subtract(Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) {
      birthDate.value = picked;
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
        addressController.text = user.address ?? '';
        detailAddressController.text = user.detailAddress ?? '';
        cleaningDetailsController.text = user.cleaningDetails ?? '';
        cleaningToolLocationController.text = user.cleaningToolLocation ?? '';
        cleaningPrecautionsController.text = user.cleaningPrecautions ?? '';
        cleaningPriceController.text = user.cleaningPrice ?? '';
        additionalOptionCostController.text = user.additionalOptionCost ?? '';
        autoRegisterTitleController.text = user.autoRegisterTitle ?? '';
        birthDate.value = user.birthDate;
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
        selectedCleaningType.value = user.preferredCleaningType ?? '숙박업소청소';
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
        address: addressController.text,
        detailAddress: detailAddressController.text,
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
        preferredCleaningType: selectedCleaningType.value,
        cleaningToolLocation: cleaningToolLocationController.text,
        cleaningPrecautions: cleaningPrecautionsController.text,
        cleaningPrice: cleaningPriceController.text,
        additionalOptionCost: additionalOptionCostController.text,
        autoRegisterTitle: autoRegisterTitleController.text,
        birthDate: birthDate.value,
      );

      await _repository.updateUserProfile(updatedUser);
      userModel.value = updatedUser;
      
      // Sync Logic
      if (user.userType == 'staff') {
        debugPrint('=== 청소 전문가 자동 등록 시작 ===');
        debugPrint('자동 등록 활성화: ${isAutoRegisterEnabled.value}');
        
        final existingStaff = await _repository.getCleaningStaffByAuthorId(user.id);
        debugPrint('기존 스태프 정보: ${existingStaff != null ? "있음 (ID: ${existingStaff.id}, 자동등록: ${existingStaff.isAutoRegistered})" : "없음"}');
        
        final availabilityStr = '근무가능일시: ${availableDays.join(', ')}\n시간: ${startTime.value != null ? _formatTime(startTime.value!) : ''} ~ ${endTime.value != null ? _formatTime(endTime.value!) : ''}';

        if (isAutoRegisterEnabled.value) {
          debugPrint('자동 등록 활성화 상태 처리 중...');
          // 자동 등록 활성화 상태
          if (existingStaff != null) {
            if (existingStaff.isAutoRegistered) {
              debugPrint('기존 자동 등록 스태프 업데이트 중...');
              // 기존 자동 등록된 스태프 -> 전체 정보 업데이트
              final updatedStaff = existingStaff.copyWith(
                authorName: updatedUser.userName ?? '',
                title: autoRegisterTitleController.text.isNotEmpty 
                    ? autoRegisterTitleController.text 
                    : existingStaff.title,
                imageUrl: updatedUser.profileImageUrl,
                address: updatedUser.address,
                latitude: updatedUser.latitude,
                longitude: updatedUser.longitude,
                content: availabilityStr,
                updatedAt: DateTime.now(),
                availableDays: availableDays.toList(),
                isAutoRegistered: true,
                cleaningType: selectedCleaningType.value,
                cleaningPrice: cleaningPriceController.text,
                additionalOptionCost: additionalOptionCostController.text,
              );
              await _repository.updateCleaningStaff(updatedStaff);
              debugPrint('자동 등록 스태프 업데이트 완료');
            } else {
              debugPrint('기존 수동 등록 스태프 프로필 정보만 동기화 중...');
              // 기존 수동 등록된 스태프 -> 프로필 정보(이름, 사진, 주소)만 동기화
              final updatedStaff = existingStaff.copyWith(
                authorName: updatedUser.userName ?? '',
                imageUrl: updatedUser.profileImageUrl,
                address: updatedUser.address,
                latitude: updatedUser.latitude,
                longitude: updatedUser.longitude,
                updatedAt: DateTime.now(),
                cleaningPrice: cleaningPriceController.text,
                additionalOptionCost: additionalOptionCostController.text,
              );
              await _repository.updateCleaningStaff(updatedStaff);
              debugPrint('수동 등록 스태프 동기화 완료');
            }
          } else {
            debugPrint('새로운 자동 등록 스태프 생성 중...');
            // 스태프 정보 없음 -> 새로 자동 등록 생성
            final newStaff = CleaningStaff(
              id: '',
              authorId: user.id,
              authorName: updatedUser.userName ?? '',
              title: autoRegisterTitleController.text.isNotEmpty 
                  ? autoRegisterTitleController.text 
                  : '청소 가능합니다',
              content: availabilityStr,
              imageUrl: updatedUser.profileImageUrl,
              address: updatedUser.address,
              latitude: updatedUser.latitude,
              longitude: updatedUser.longitude,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              availableDays: availableDays.toList(),
              isAutoRegistered: true,
              cleaningType: selectedCleaningType.value,
              cleaningPrice: cleaningPriceController.text,
              additionalOptionCost: additionalOptionCostController.text,
            );
            await _repository.createCleaningStaff(newStaff);
            debugPrint('새 자동 등록 스태프 생성 완료');
          }
        } else {
          debugPrint('자동 등록 비활성화 상태 처리 중...');
          // 자동 등록 비활성화 상태
          if (existingStaff != null) {
            if (existingStaff.isAutoRegistered) {
              debugPrint('자동 등록 스태프 삭제 중...');
              // 자동 등록된 스태프라면 삭제
              await _repository.deleteCleaningStaff(existingStaff.id);
              debugPrint('자동 등록 스태프 삭제 완료');
            } else {
              debugPrint('수동 등록 스태프 프로필 정보만 동기화 중...');
              // 수동 등록된 스태프라면 -> 프로필 정보(이름, 사진, 주소)만 동기화
              final updatedStaff = existingStaff.copyWith(
                authorName: updatedUser.userName ?? '',
                imageUrl: updatedUser.profileImageUrl,
                address: updatedUser.address,
                latitude: updatedUser.latitude,
                longitude: updatedUser.longitude,
                updatedAt: DateTime.now(),
                cleaningPrice: cleaningPriceController.text,
                additionalOptionCost: additionalOptionCostController.text,
              );
              await _repository.updateCleaningStaff(updatedStaff);
              debugPrint('수동 등록 스태프 동기화 완료');
            }
          }
        }
        debugPrint('=== 청소 전문가 자동 등록 완료 ===');
      } else if (user.userType == 'owner') {
        // Owner Logic
        final existingRequest = await _repository.getCleaningRequestByAuthorId(user.id);
        
        // 수정 가능한 상태인지 확인 (pending 상태일 때만 수정 가능)
        bool isEditable = existingRequest != null && existingRequest.status == 'pending';
        
        final contentStr = '청소 필요 요일: ${availableDays.join(', ')}\n시간: ${startTime.value != null ? _formatTime(startTime.value!) : ''} ~ ${endTime.value != null ? _formatTime(endTime.value!) : ''}\n상세: ${cleaningDetailsController.text}${cleaningToolLocationController.text.isNotEmpty ? '\n청소도구위치: ${cleaningToolLocationController.text}' : ''}${cleaningPrecautionsController.text.isNotEmpty ? '\n주의사항: ${cleaningPrecautionsController.text}' : ''}';

        if (isAutoRegisterEnabled.value) {
          if (isEditable && existingRequest!.isAutoRegistered) {
            // 기존 대기중인 자동 등록 의뢰 -> 전체 정보 업데이트
            final updatedRequest = existingRequest.copyWith(
              authorName: updatedUser.userName ?? '',
              title: autoRegisterTitleController.text.isNotEmpty 
                  ? autoRegisterTitleController.text 
                  : existingRequest.title,
              imageUrl: updatedUser.profileImageUrl,
              address: updatedUser.address,
              latitude: updatedUser.latitude,
              longitude: updatedUser.longitude,
              content: contentStr,
              updatedAt: DateTime.now(),
              availableDays: availableDays.toList(),
              isAutoRegistered: true,
              cleaningType: selectedCleaningType.value,
              cleaningToolLocation: cleaningToolLocationController.text,
              precautions: cleaningPrecautionsController.text,
            );
            await _repository.updateCleaningRequest(updatedRequest);
          } else if (isEditable && !existingRequest!.isAutoRegistered) {
            // 기존 대기중인 수동 등록 의뢰 -> 프로필 정보(이름, 사진, 주소)만 동기화
            final updatedRequest = existingRequest.copyWith(
              authorName: updatedUser.userName ?? '',
              imageUrl: updatedUser.profileImageUrl,
              address: updatedUser.address,
              latitude: updatedUser.latitude,
              longitude: updatedUser.longitude,
              updatedAt: DateTime.now(),
            );
            await _repository.updateCleaningRequest(updatedRequest);
          } else {
            // 대기중인 의뢰가 없거나(완료/진행중 포함) -> 새로 자동 등록 생성
            // 단, 이미 진행중/완료된 의뢰가 있어도 새로운 의뢰를 생성함 (다음 청소 건)
            final newRequest = CleaningRequest(
              id: '',
              authorId: user.id,
              authorName: updatedUser.userName ?? '',
              title: autoRegisterTitleController.text.isNotEmpty 
                  ? autoRegisterTitleController.text 
                  : '${updatedUser.userName}님의 청소 의뢰',
              content: contentStr,
              price: '협의', // Default price
              imageUrl: updatedUser.profileImageUrl,
              address: updatedUser.address,
              latitude: updatedUser.latitude,
              longitude: updatedUser.longitude,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              status: 'pending',
              availableDays: availableDays.toList(),
              isAutoRegistered: true,
              cleaningType: selectedCleaningType.value,
              cleaningToolLocation: cleaningToolLocationController.text,
              precautions: cleaningPrecautionsController.text,
            );
            await _repository.createCleaningRequest(newRequest);
          }
        } else {
          // 자동 등록 비활성화 상태
          if (isEditable && existingRequest!.isAutoRegistered) {
            // 대기중인 자동 등록 의뢰라면 삭제
            await _repository.deleteCleaningRequest(existingRequest.id);
          } else if (isEditable && !existingRequest!.isAutoRegistered) {
            // 대기중인 수동 등록 의뢰라면 -> 프로필 정보(이름, 사진, 주소)만 동기화
            final updatedRequest = existingRequest.copyWith(
              authorName: updatedUser.userName ?? '',
              imageUrl: updatedUser.profileImageUrl,
              address: updatedUser.address,
              latitude: updatedUser.latitude,
              longitude: updatedUser.longitude,
              updatedAt: DateTime.now(),
            );
            await _repository.updateCleaningRequest(updatedRequest);
          }
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
            preferredCleaningType: user.preferredCleaningType,
            birthDate: user.birthDate,
          );

          await _repository.updateUserProfile(updatedUser);
          userModel.value = updatedUser;
          addressController.text = result.address; // Sync controller
          
          Get.snackbar('알림', '주소가 업데이트되었습니다');
        }
      },
    ));
  }

  Future<void> logout() async {
    await _auth.signOut();
    // 모든 GetX 컨트롤러 삭제
    Get.deleteAll(force: true);
    // 모든 페이지 스택 제거하고 로그인 페이지로 이동
    Get.offAll(() => LoginSignupPage(), predicate: (_) => false);

  }
}
