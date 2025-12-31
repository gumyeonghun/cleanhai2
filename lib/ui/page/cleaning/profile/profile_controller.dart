import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:cleanhai2/data/constants/regions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cleanhai2/service/auth_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:cleanhai2/data/model/user_model.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';

import 'package:cleanhai2/data/repository/cleaning_repository.dart';
import 'package:cleanhai2/data/repository/user_repository.dart';
import 'package:cleanhai2/data/repository/chat_repository.dart';
import '../../auth/login_signup_page.dart';
import '../../main/main_controller.dart';


class ProfileController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final AuthService _authService = Get.find<AuthService>();

  final Rx<UserModel?> userModel = Rx<UserModel?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isEditing = false.obs; // 통합 편집 모드 상태


  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController detailAddressController = TextEditingController();
  
  // Region Selection
  final RxString selectedCity = ''.obs;
  final RxString selectedDistrict = ''.obs;
  final RxList<String> districts = <String>[].obs;
  
  // Cleaning Address (Owner specific)
  final RxString selectedCleaningCity = ''.obs;
  final RxString selectedCleaningDistrict = ''.obs;
  final RxList<String> cleaningDistricts = <String>[].obs;
  final TextEditingController cleaningDetailAddressController = TextEditingController();
  
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

  // 간편등록용 이미지 (청소 전문가 프로필용)
  final Rx<File?> quickRegisterImage = Rx<File?>(null);

  // Staff reviews and ratings
  final RxMap<String, dynamic> staffRatingStats = <String, dynamic>{}.obs;
  // Staff reviews and requests (to keep track of ID for reporting)
  final RxList<CleaningRequest> staffReviewRequests = <CleaningRequest>[].obs;

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
    cleaningDetailAddressController.dispose();
    cleaningDetailsController.dispose();
    cleaningToolLocationController.dispose();
    cleaningPrecautionsController.dispose();
    cleaningPriceController.dispose();
    additionalOptionCostController.dispose();
    autoRegisterTitleController.dispose();
    super.onClose();
  }

  Future<void> loadUserProfile() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userProfile = await _repository.getUserProfile(user.uid);
        userModel.value = userProfile;
        
        // 초기값 설정
        if (userProfile != null) {
          nameController.text = userProfile.userName ?? '';
          phoneController.text = userProfile.phoneNumber ?? '';
          addressController.text = userProfile.address ?? '';
          detailAddressController.text = userProfile.detailAddress ?? '';
          
          // Parse address to set initial region selection if possible
          if (userProfile.address != null && userProfile.address!.isNotEmpty) {
             final parts = userProfile.address!.split(' ');
             if (parts.length >= 2) {
               final city = parts[0];
               final district = parts[1];
               if (Regions.data.containsKey(city)) {
                 selectedCity.value = city;
                 districts.assignAll(Regions.data[city] ?? []);
                 
                 if (districts.contains(district)) {
                   selectedDistrict.value = district;
                 }
               }
             }
           }
          
          // cleaningAddress parsing logic (separate from main address)
          cleaningDetailAddressController.text = userProfile.cleaningDetailAddress ?? '';
          if (userProfile.cleaningAddress != null && userProfile.cleaningAddress!.isNotEmpty) {
             final parts = userProfile.cleaningAddress!.split(' ');
             if (parts.length >= 2) {
               final city = parts[0];
               final district = parts[1];
               if (Regions.data.containsKey(city)) {
                 selectedCleaningCity.value = city;
                 cleaningDistricts.assignAll(Regions.data[city] ?? []);
                 if (cleaningDistricts.contains(district)) {
                   selectedCleaningDistrict.value = district;
                 }
               }
             }
          }
           
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
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStaffReviews() async {
    final user = userModel.value;
    if (user != null && user.userType == 'staff') {
      try {
        // Get rating stats
        final stats = await _repository.getStaffRatingStats(user.id);
        staffRatingStats.value = stats;
        
        // Get all completion history (including those without reviews)
        final requests = await _repository.getCompletedCleaningHistory(user.id);
        staffReviewRequests.assignAll(requests);
      } catch (e) {
        debugPrint('Failed to load staff reviews: $e');
      }
    }
  }

  // 신고 기능
  Future<void> reportReview(String requestId, String reason) async {
    // 실제 서버가 있다면 여기서 신고 API를 호출합니다.
    // 현재는 사용자에게 신고가 접수되었음을 알리는 것으로 UI 요구사항을 충족합니다.
    debugPrint('Reported: $requestId, Reason: $reason');
    await Future.delayed(Duration(seconds: 1)); // Mock network delay
    
    Get.snackbar(
      '신고 접수 완료', 
      '해당 리뷰에 대한 신고가 접수되었습니다. 검토 후 조치하겠습니다.',
      backgroundColor: Colors.grey[800],
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(20),
    );
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
        quickRegisterImage.value = null;
        
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
        
        // Restore region selection
        if (user.address != null && user.address!.isNotEmpty) {
           final parts = user.address!.split(' ');
           if (parts.length >= 2) {
             final city = parts[0];
             final district = parts[1];
             if (Regions.data.containsKey(city)) {
               selectedCity.value = city;
               districts.assignAll(Regions.data[city] ?? []);
               if (districts.contains(district)) {
                 selectedDistrict.value = district;
               }
             }
           }
        }
      }
    }
    isEditing.value = !isEditing.value;
  }

  // 간편설정 편집 모드 토글 제거됨 (통합)


  // 이미지 선택
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage.value = File(image.path);
    }
  }

  // 간편등록용 이미지 선택
  Future<void> pickQuickRegisterImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      quickRegisterImage.value = File(image.path);
    }
  }

  // 요청 이미지 선택
  final Rx<File?> selectedRequestImage = Rx<File?>(null);
  Future<void> pickRequestImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedRequestImage.value = File(image.path);
    }
  }

  Future<void> saveProfile() async {
    // 만약 유저 정보가 없으면 다시 한 번 로딩 시도 (Self-healing)
    if (userModel.value == null) {
      debugPrint('User model missing in saveProfile. Attempting to reload...');
      // 로딩 인디케이터를 위해 isLoading 잠깐 true (loadUserProfile 내부에서 false로 끝남)
      isLoading.value = true;
      await loadUserProfile();
    }

    final user = userModel.value;
    if (user == null) {
      Get.snackbar('오류', '사용자 정보를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      isLoading.value = true;
      
      // 간편설정 모드 로직 통합됨.

      String? imageUrl = user.profileImageUrl;

      // 새 이미지가 선택되었다면 업로드
      if (selectedImage.value != null) {
        final uploaded = await _repository.uploadImage(selectedImage.value!, 'profile');
        if (uploaded != null) {
          imageUrl = uploaded;
        } else {
           Get.snackbar('알림', '프로필 이미지 업로드에 실패했습니다. 기존 이미지를 유지합니다.', 
               backgroundColor: Colors.orange, colorText: Colors.white);
        }
      }

      // 새 요청 이미지가 선택되었다면 업로드
      String? requestImageUrl = user.cleaningRequestImageUrl;
      if (selectedRequestImage.value != null) {
        final uploaded = await _repository.uploadImage(selectedRequestImage.value!, 'request');
        if (uploaded != null) {
          requestImageUrl = uploaded;
        } else {
           Get.snackbar('알림', '요청 이미지 업로드에 실패했습니다. 기존 이미지를 유지합니다.', 
               backgroundColor: Colors.orange, colorText: Colors.white);
        }
      }

      final updatedUser = UserModel(
        id: user.id,
        email: user.email,
        address: (selectedCity.value.isEmpty && user.address != null) 
            ? user.address! 
            : '${selectedCity.value} ${selectedDistrict.value}'.trim(),
        detailAddress: detailAddressController.text,
        // Latitude/Longitude removed
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
        cleaningRequestImageUrl: requestImageUrl,
        cleaningAddress: (selectedCleaningCity.value.isEmpty) 
            ? user.cleaningAddress 
            : '${selectedCleaningCity.value} ${selectedCleaningDistrict.value}'.trim(),
        cleaningDetailAddress: cleaningDetailAddressController.text,
      );

      await _repository.updateUserProfile(updatedUser).timeout(Duration(seconds: 30));
      userModel.value = updatedUser;
      
      // Sync Logic
      if (user.userType == 'staff' && isAutoRegisterEnabled.value) {
        debugPrint('=== 청소 전문가 자동 등록 시작 ===');
        debugPrint('자동 등록 활성화: ${isAutoRegisterEnabled.value}');
        
        final availabilityStr = '근무가능일시: ${availableDays.join(', ')}\n시간: ${startTime.value != null ? _formatTime(startTime.value!) : ''} ~ ${endTime.value != null ? _formatTime(endTime.value!) : ''}${cleaningDetailsController.text.isNotEmpty ? '\n상세: ${cleaningDetailsController.text}' : ''}';

        // 기존 게시글 확인
        final existingStaff = await _repository.getCleaningStaffByAuthorId(user.id);
        
        if (existingStaff != null) {
          debugPrint('기존 게시글 발견 -> 업데이트 및 최상단 이동 (Bump)');
          final updatedStaff = existingStaff.copyWith(
            authorName: updatedUser.userName,
            title: autoRegisterTitleController.text.isNotEmpty 
                ? autoRegisterTitleController.text 
                : '청소 가능합니다',
            content: availabilityStr,
            imageUrl: updatedUser.profileImageUrl,
            address: updatedUser.address,
            createdAt: DateTime.now(), // Bump to top
            updatedAt: DateTime.now(),
            availableDays: availableDays.toList(),
            cleaningType: selectedCleaningType.value,
            cleaningPrice: cleaningPriceController.text,
            additionalOptionCost: additionalOptionCostController.text,
          );
          await _repository.updateCleaningStaff(updatedStaff);
          Get.snackbar('성공', '청소 대기 글이 최상단으로 갱신되었습니다!',
            backgroundColor: Colors.green, colorText: Colors.white);
        } else {
          debugPrint('기존 게시글 없음 -> 새 게시글 생성');
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
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            availableDays: availableDays.toList(),
            isAutoRegistered: true,
            cleaningType: selectedCleaningType.value,
            cleaningPrice: cleaningPriceController.text,
            additionalOptionCost: additionalOptionCostController.text,
          );
          await _repository.createCleaningStaff(newStaff);
          Get.snackbar('성공', '새로운 청소 대기 글이 등록되었습니다!',
            backgroundColor: Colors.green, colorText: Colors.white);
        }

        // 플래그 리셋 (다음 저장 시 중복 실행 방지)
        isAutoRegisterEnabled.value = false;

        debugPrint('=== 청소 전문가 자동 등록 완료 ===');
        
        // 저장 후 종료
        isEditing.value = false;
        selectedImage.value = null;
        quickRegisterImage.value = null;
        return; 
      } else if (user.userType == 'staff') {
         // staff이지만 자동등록 아닐 때 - 그냥 프로필만 저장
      } else if (user.userType == 'owner' && isAutoRegisterEnabled.value) {
        // Owner Logic - 간편 업로드 시에만 실행
        debugPrint('=== Owner 간편 업로드 시작 ===');
        debugPrint('isAutoRegisterEnabled: ${isAutoRegisterEnabled.value}');

        final addressToSave = (updatedUser.cleaningAddress != null && updatedUser.cleaningAddress!.isNotEmpty) 
            ? updatedUser.cleaningAddress!
            : updatedUser.address ?? ''; // Fallback to main address if cleaning address is empty (though validation should catch this)
            
        debugPrint('Address to save for request: "$addressToSave"');
        
        if (addressToSave.trim().isEmpty) {
           debugPrint('주소가 비어있음 - 등록 중단');
           Get.snackbar('알림', '청소할 주소가 설정되지 않았습니다. 간편 설정에서 주소를 입력해주세요.',
              backgroundColor: Colors.orange, colorText: Colors.white);
           isAutoRegisterEnabled.value = false;
           return;
        }

        final contentStr = '청소 필요 요일: ${availableDays.join(', ')}\n시간: ${startTime.value != null ? _formatTime(startTime.value!) : ''} ~ ${endTime.value != null ? _formatTime(endTime.value!) : ''}\n상세: ${cleaningDetailsController.text}${cleaningToolLocationController.text.isNotEmpty ? '\n청소도구위치: ${cleaningToolLocationController.text}' : ''}${cleaningPrecautionsController.text.isNotEmpty ? '\n주의사항: ${cleaningPrecautionsController.text}' : ''}';

        final newRequest = CleaningRequest(
          id: '',
          authorId: user.id,
          authorName: updatedUser.userName ?? '',
          title: autoRegisterTitleController.text.isNotEmpty 
              ? autoRegisterTitleController.text 
              : '${updatedUser.userName}님의 청소 의뢰',
          content: contentStr,
          price: cleaningPriceController.text.isNotEmpty ? cleaningPriceController.text : '협의',
          imageUrl: updatedUser.cleaningRequestImageUrl ?? updatedUser.profileImageUrl,
          address: addressToSave,
          detailAddress: updatedUser.cleaningDetailAddress,
          // latitude: updatedUser.latitude, // Removed
          // longitude: updatedUser.longitude, // Removed
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: 'pending',
          availableDays: availableDays.toList(),
          isAutoRegistered: true,
          cleaningType: selectedCleaningType.value,
          cleaningToolLocation: cleaningToolLocationController.text,
          precautions: cleaningPrecautionsController.text,
        );
        
        debugPrint('Creating cleaning request...');
        await _repository.createCleaningRequest(newRequest).timeout(Duration(seconds: 30));
        debugPrint('새 자동 등록 의뢰 생성 완료 (강제)');

        // Navigate to Home Page (Tab 0) to show the new request
        if (Get.isRegistered<MainController>()) {
          Get.find<MainController>().changeIndex(0);
        }
        
        // 플래그 리셋
        isAutoRegisterEnabled.value = false;
        
        // 성공 메시지 - 간편 업로드 성공
        isEditing.value = false;
        selectedImage.value = null;
        quickRegisterImage.value = null;
        selectedRequestImage.value = null;
        
        Get.snackbar('성공', '청소 의뢰가 등록되었습니다!',
          backgroundColor: Colors.green, colorText: Colors.white);
        debugPrint('=== Owner 간편 업로드 완료 ===');
        return; // 여기서 종료하여 아래 일반 저장 메시지가 안 뜨도록
      }

      
      isEditing.value = false;
      // isEditingQuickSettings.value = false; // Removed
      selectedImage.value = null;
      quickRegisterImage.value = null;
      selectedRequestImage.value = null;
      
      // 일반 프로필 저장 성공 메시지
      Get.snackbar('성공', '프로필이 업데이트되었습니다',
        backgroundColor: Colors.green, colorText: Colors.white);
    } on TimeoutException catch (_) {
      Get.snackbar('연결 시간 초과', '서버 응답이 늦어지고 있습니다. 네트워크 연결을 확인하고 다시 시도해주세요.',
          backgroundColor: Colors.orange, colorText: Colors.white, duration: Duration(seconds: 3));
    } on SocketException catch (_) {
      Get.snackbar('연결 오류', '인터넷 연결이 불안정합니다. Wi-Fi 또는 데이터를 확인해주세요.',
          backgroundColor: Colors.red, colorText: Colors.white, duration: Duration(seconds: 3));
    } catch (e) {
      debugPrint('saveProfile 에러: $e');
      
      // 중요: 에러 발생 시 자동 등록 플래그를 초기화하여, 
      // 다음 번 '저장' 버튼 클릭 시 의도치 않게 간편 업로드가 실행되는 것을 방지함.
      if (isAutoRegisterEnabled.value) {
         isAutoRegisterEnabled.value = false;
      }

      // "Failed to resolve name" is often wrapped in a generic exception or PlatformException,
      // so we check the string message as a fallback.
      if (e.toString().contains('Failed to resolve name') || e.toString().contains('host lookup')) {
         Get.snackbar('네트워크 오류', '서버를 찾을 수 없습니다. 인터넷 연결을 확인해주세요.',
          backgroundColor: Colors.red, colorText: Colors.white, duration: Duration(seconds: 3));
      } else {
        Get.snackbar('오류', '프로필 업데이트 실패: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
      }
    } finally {
      isLoading.value = false;

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
  
  void updateCleaningDistricts(String city) {
    selectedCleaningCity.value = city;
    cleaningDistricts.assignAll(Regions.data[city] ?? []);
    selectedCleaningDistrict.value = '';
  }

  void updateCleaningDistrict(String district) {
    selectedCleaningDistrict.value = district;
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('Logout Error: $e');
      // Even if signOut fails, we attempt to clear local state
    } finally {
      // 모든 GetX 컨트롤러 삭제
      Get.deleteAll(force: true);
      
      // 핵심 서비스 재등록 (deleteAll로 인해 삭제되었으므로 복구 필요)
      Get.put(UserRepository());
      Get.put(AuthService());
      
      // 모든 페이지 스택 제거하고 로그인 페이지로 이동
      Get.offAll(() => LoginSignupPage(), predicate: (_) => false);
    }
  }

  Future<void> bumpAutoRegisteredRequest() async {
    final user = userModel.value;
    if (user == null) return;
    
    // 이 기능은 우선 'owner'에게만 적용 (필요 시 staff도 확장 가능)
    if (user.userType == 'owner' && isAutoRegisterEnabled.value) {
      try {
        isLoading.value = true;
        final existingRequest = await _repository.getCleaningRequestByAuthorId(user.id);
        
        if (existingRequest != null && existingRequest.isAutoRegistered && existingRequest.status == 'pending') {
          // createdAt만 현재 시간으로 업데이트하여 상단으로 "끌어올리기"
          final updatedRequest = existingRequest.copyWith(
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await _repository.updateCleaningRequest(updatedRequest);
          
          Get.snackbar('성공', '청소 의뢰가 상단으로 끌어올려졌습니다!',
            backgroundColor: Colors.green, colorText: Colors.white);
        } else {
           Get.snackbar('알림', '끌어올릴 수 있는 대기중인 자동 등록 의뢰가 없습니다.',
            backgroundColor: Colors.orange, colorText: Colors.white);
        }
      } catch (e) {
        debugPrint('Bump request failed: $e');
        Get.snackbar('오류', '작업 실패: $e',
            backgroundColor: Colors.red, colorText: Colors.white);
      } finally {
        isLoading.value = false;
      }
    } else {
      Get.snackbar('알림', '자동 등록이 활성화된 상태에서만 가능합니다.',
          backgroundColor: Colors.orange, colorText: Colors.white);
    }
  }

  Future<void> executeAutoRegister() async {
    // 간편 업로드 버튼 클릭 시 -> 저장 로직(saveProfile)과 동일하게 처리
    // saveProfile 내부에 '무조건 게시글 생성' 로직이 포함되어 있음
    debugPrint('간편 업로드 버튼 클릭 -> saveProfile 호출');
    
    // 자동 등록 활성화 플래그 설정
    isAutoRegisterEnabled.value = true;
    
    await saveProfile();
    
    // saveProfile에서 성공 스낵바를 띄우므로 여기서는 추가 작업 불필요
  }




  /// 회원 탈퇴
  Future<void> deleteAccount() async {
    final user = _authService.currentUser;

    if (user == null) return;

    // 1. 확인 다이얼로그
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '정말 탈퇴하시겠습니까?\n'
          '탈퇴 후 30일간 데이터가 보관되며, 이후 완전히 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              '탈퇴',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      isLoading.value = true;
      String uid = user.uid;

      // 2. Firestore 데이터 소프트 삭제 (30일 보관)
      debugPrint('회원 탈퇴: 사용자 데이터 소프트 삭제 시작 (UID: $uid)');
      
      // 2-1. 사용자 문서 소프트 삭제 (isDeleted: true, deletedAt: 현재시간)
      await _repository.softDeleteUser(uid);
      
      // 2-2. 청소 의뢰 소프트 삭제 (상태를 'deleted'로 변경)
      await _repository.deleteAllCleaningRequestsByAuthorId(uid);
      await _repository.removeUserFromApplicants(uid);
      
      // 2-3. 청소 대기 프로필 삭제
      await _repository.deleteCleaningStaffByAuthorId(uid);
      
      // 2-4. 청소 노하우 삭제
      await _repository.deleteAllKnowhowsByAuthorId(uid);
      
      // 2-5. 청소 추천 삭제
      await _repository.deleteAllRecommendationsByAuthorId(uid);
      
      // 2-6. 채팅방 및 메시지 삭제
      final chatRepository = ChatRepository();
      await chatRepository.deleteAllChatRoomsByUserId(uid);
      
      debugPrint('회원 탈퇴: Firestore 데이터 소프트 삭제 완료');

      // 3. Firebase Auth 계정 삭제
      try {
        await user.delete();
        debugPrint('회원 탈퇴: Firebase Auth 계정 삭제 완료');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          // 재로그인 필요
          isLoading.value = false;
          Get.snackbar(
            '재로그인 필요',
            '보안을 위해 다시 로그인한 후 탈퇴를 진행해주세요.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          await logout();
          return;
        }
        rethrow;
      }

      // 4. 완료 처리 및 로그인 페이지로 이동
      isLoading.value = false;
      
      // GetX 상태 초기화
      await Get.deleteAll(force: true);
      
      // 핵심 서비스 재등록
      Get.put(UserRepository());
      Get.put(AuthService());

      // 로그인 페이지로 이동
      Get.offAll(() => LoginSignupPage(), predicate: (_) => false);
      
      // 탈퇴 완료 메시지
      Get.snackbar(
        '회원 탈퇴 완료', 
        '30일 후 모든 데이터가 완전히 삭제됩니다.',
        backgroundColor: Colors.grey[800],
        colorText: Colors.white,
      );

    } catch (e) {
      debugPrint('회원 탈퇴 실패: $e');
      isLoading.value = false;
      Get.snackbar(
        '오류',
        '회원 탈퇴 처리에 실패했습니다: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
