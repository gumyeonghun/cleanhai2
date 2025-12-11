import 'package:get/get.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanhai2/data/model/user_model.dart';
import 'package:cleanhai2/utils/location_utils.dart';

class CleaningController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final RxList<CleaningRequest> cleaningRequests = <CleaningRequest>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  
  // Cleaning type filter (Body)
  final RxString selectedCleaningTypeFilter = '전체'.obs;
  static const List<String> cleaningTypeFilters = [
    '전체',
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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
    bindCleaningRequests();
  }

  Future<void> loadUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      currentUser.value = await _repository.getUserProfile(user.uid);
    }
  }

  void bindCleaningRequests() {
    cleaningRequests.bindStream(_repository.getCleaningRequests());
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  List<CleaningRequest> get sortedRequests {
    List<CleaningRequest> requests = cleaningRequests;
    
    // Cleaning Type Filter (Body)
    if (selectedCleaningTypeFilter.value != '전체') {
      requests = requests.where((request) {
        return request.cleaningType == selectedCleaningTypeFilter.value;
      }).toList();
    }
      
      // 검색어 필터링
      if (searchQuery.value.isNotEmpty) {
        requests = requests.where((request) {
          final query = searchQuery.value.toLowerCase();
          final matchesQuery = request.title.toLowerCase().contains(query) ||
                 request.content.toLowerCase().contains(query) ||
                 request.authorName.toLowerCase().contains(query) ||
                 (request.address?.toLowerCase().contains(query) ?? false);
          
          if (!matchesQuery) return false;

          // Visibility Filter
          final user = currentUser.value;
          if (user == null) return request.targetStaffId == null; // Guest sees only public requests

          // Show if:
          // 1. It's a public request (no target)
          // 2. I am the target staff
          // 3. I am the author
          return request.targetStaffId == null || 
                 request.targetStaffId == user.id || 
                 request.authorId == user.id;
        }).toList();
      } else {
        // 검색어가 없을 때도 필터링 적용
        requests = requests.where((request) {
          final user = currentUser.value;
          if (user == null) return request.targetStaffId == null;

          return request.targetStaffId == null || 
                 request.targetStaffId == user.id || 
                 request.authorId == user.id;
        }).toList();
      }
      
      // 자동 등록된 의뢰는 오늘 요일에 해당하는 것만 표시
      final today = DateTime.now();
      final dayNames = ['일', '월', '화', '수', '목', '금', '토'];
      final todayDayName = dayNames[today.weekday % 7];
      
      requests = requests.where((request) {
        // 자동 등록이 아니면 항상 표시
        if (!request.isAutoRegistered) return true;
        
        // 자동 등록이지만 availableDays가 없으면 표시하지 않음
        if (request.availableDays == null || request.availableDays!.isEmpty) return false;
        
        // 오늘 요일이 포함되어 있으면 표시
        return request.availableDays!.contains(todayDayName);
      }).toList();
    
    if (currentUser.value == null || 
        currentUser.value!.latitude == null || 
        currentUser.value!.longitude == null) {
      return requests;
    }

    final userLat = currentUser.value!.latitude!;
    final userLng = currentUser.value!.longitude!;

    final sortedList = List<CleaningRequest>.from(requests);
    
    // 전체청소일 때는 시간순 (최신순) 정렬
    if (selectedCleaningTypeFilter.value == '전체') {
      sortedList.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return sortedList;
    }

    // 그 외에는 거리순 정렬
    sortedList.sort((a, b) {
      // 위치 정보가 없는 항목은 뒤로 보냄
      if (a.latitude == null || a.longitude == null) return 1;
      if (b.latitude == null || b.longitude == null) return -1;

      final distA = LocationUtils.calculateDistance(userLat, userLng, a.latitude!, a.longitude!);
      final distB = LocationUtils.calculateDistance(userLat, userLng, b.latitude!, b.longitude!);

      return distA.compareTo(distB);
    });
    
    return sortedList;
  }

  // Add other methods as needed for HomePage, DetailPage, etc.
}
