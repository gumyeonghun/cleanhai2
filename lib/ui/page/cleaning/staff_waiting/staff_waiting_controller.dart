import 'package:get/get.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanhai2/data/model/user_model.dart';
import 'package:cleanhai2/utils/location_utils.dart';
import 'package:flutter/material.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart' as staff_model;

class StaffWaitingController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  
  final RxList<CleaningStaff> waitingStaff = <CleaningStaff>[].obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;
  
  // 각 staff의 평점 정보 저장 (staffId -> {averageRating, reviewCount})
  final RxMap<String, Map<String, dynamic>> staffRatings = <String, Map<String, dynamic>>{}.obs;
  
  // 내가 신청한 의뢰 상태 저장 (targetStaffId -> status)
  final RxMap<String, String> myRequestStatus = <String, String>{}.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isFabExpanded = false.obs;

  // Cleaning type filter
  final RxString selectedCleaningTypeFilter = '전체청소'.obs;
  static const List<String> cleaningTypeFilters = [
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

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
    loadWaitingStaff();
    loadMyRequests();
  }

  Future<void> loadUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      currentUser.value = await _repository.getUserProfile(user.uid);
    }
  }

  void loadMyRequests() {
    final user = _auth.currentUser;
    if (user != null) {
      _repository.getAllMyRequestsAsOwner(user.uid).listen((requests) {
        final statusMap = <String, String>{};
        for (var request in requests) {
          if (request.targetStaffId != null && request.targetStaffId!.isNotEmpty) {
            // 이미 상태가 있거나 더 중요한 상태(진행중 > 수락됨 > 대기중)라면 업데이트
            // 여기서는 간단하게 가장 최신의 요청 상태를 우선시하거나,
            // 특정 상태 우선순위를 둘 수 있음. 
            // 일단 완료된 것은 제외하고 진행중/수락됨/대기중을 표시한다고 가정.
            if (request.status != 'completed') {
               statusMap[request.targetStaffId!] = request.status;
            }
          }
        }
        myRequestStatus.assignAll(statusMap);
      });
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  List<CleaningStaff> get sortedStaff {
    List<CleaningStaff> staff = waitingStaff;
    
    // 청소 종류 필터링 (CleaningStaff 모델에 cleaningType 필드가 있다고 가정하거나, title/content에서 검색)
    // 현재 CleaningStaff 모델에는 cleaningType 필드가 명시적으로 보이지 않지만, 
    // 이전 대화 맥락상 프로필에 청소 종류를 설정하는 기능이 있었음.
    // 만약 cleaningType 필드가 없다면 title이나 content에 포함되어 있는지로 임시 필터링.
    // 하지만 정확한 필터링을 위해 CleaningStaff 모델 확인이 필요할 수 있음.
    // 일단 title/content 기반으로 필터링 구현.
    if (selectedCleaningTypeFilter.value != '전체청소') {
      staff = staff.where((s) {
        // CleaningStaff 모델에 cleaningType이 있으면 그것으로 비교, 없으면 title/content 검색
        if (s.cleaningType != null && s.cleaningType!.isNotEmpty) {
          return s.cleaningType == selectedCleaningTypeFilter.value;
        }
        return s.title.contains(selectedCleaningTypeFilter.value) || 
               s.content.contains(selectedCleaningTypeFilter.value);
      }).toList();
    }

    // 검색어 필터링
    if (searchQuery.value.isNotEmpty) {
      staff = staff.where((s) {
        final query = searchQuery.value.toLowerCase();
        return s.authorName.toLowerCase().contains(query) ||
               s.title.toLowerCase().contains(query) ||
               s.content.toLowerCase().contains(query) ||
               (s.address?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // Date filtering removed as per user request (Show all regardless of date)
    
    if (currentUser.value == null || 
        currentUser.value!.latitude == null || 
        currentUser.value!.longitude == null) {
      return staff;
    }

    final userLat = currentUser.value!.latitude!;
    final userLng = currentUser.value!.longitude!;

    final sortedList = List<CleaningStaff>.from(staff);
    
    // 전체청소일 때는 시간순 (최신순) 정렬
    if (selectedCleaningTypeFilter.value == '전체청소') {
      sortedList.sort((a, b) {
        // if (a.createdAt == null || b.createdAt == null) return 0; // Removed unnecessary check
        return b.createdAt.compareTo(a.createdAt);
      });
      return sortedList;
    }

    // 그 외에는 거리순 정렬
    sortedList.sort((a, b) {
      if (a.latitude == null || a.longitude == null) return 1;
      if (b.latitude == null || b.longitude == null) return -1;

      final distA = LocationUtils.calculateDistance(userLat, userLng, a.latitude!, a.longitude!);
      final distB = LocationUtils.calculateDistance(userLat, userLng, b.latitude!, b.longitude!);

      return distA.compareTo(distB);
    });
    
    return sortedList;
  }

  void loadWaitingStaff() {
    isLoading.value = true;
    try {
      // Use stream for real-time updates
      _repository.getCleaningStaffs().listen((staff) {
        waitingStaff.assignAll(staff);
        
        // Load rating stats for each staff
        for (var s in staff) {
          _repository.getStaffRatingStats(s.authorId).then((stats) {
            staffRatings[s.authorId] = stats;
          });
        }
        
        isLoading.value = false;
      });
    } catch (e) {
      debugPrint('Error loading waiting staff: $e');
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    // Stream automatically updates, just trigger a reload
    loadWaitingStaff();
  }

  void toggleFab() {
    isFabExpanded.value = !isFabExpanded.value;
  }

  Future<void> registerWithProfile() async {
    final user = currentUser.value;
    if (user == null) {
      Get.snackbar('오류', '사용자 정보를 찾을 수 없습니다.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (user.userType != 'staff') {
      Get.snackbar('알림', '청소 전문가만 등록할 수 있습니다.', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    try {
      // 프로필 정보로 청소 대기 등록
      final availabilityStr = '근무 가능: ${user.availableDays?.join(', ') ?? '미설정'}\n시간: ${user.availableStartTime ?? ''} ~ ${user.availableEndTime ?? ''}';
      
      final newStaff = staff_model.CleaningStaff(
        id: '',
        authorId: user.id,
        authorName: user.userName ?? '이름 없음',
        title: '청소 가능합니다',
        content: availabilityStr,
        imageUrl: user.profileImageUrl,
        address: user.address,
        latitude: user.latitude,
        longitude: user.longitude,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repository.createCleaningStaff(newStaff);
      await refresh();
      
      Get.snackbar('성공', '프로필 정보로 등록되었습니다!', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('오류', '등록 중 오류가 발생했습니다: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
