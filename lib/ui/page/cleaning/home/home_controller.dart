import 'package:get/get.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanhai2/data/model/user_model.dart';
import 'package:cleanhai2/data/constants/regions.dart';

class CleaningController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final RxList<CleaningRequest> cleaningRequests = <CleaningRequest>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // Region Filters
  final RxString selectedCity = ''.obs;
  final RxString selectedDistrict = ''.obs;
  final RxList<String> districts = <String>[].obs;
  
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

  // Optimized: Cache the sorted list to avoid re-calculation on every build
  final RxList<CleaningRequest> sortedRequests = <CleaningRequest>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
    bindCleaningRequests();
    
    // Optimize: Update sorted list only when dependencies change
    // Using `debounce` for search query to avoid too many updates while typing
    debounce(searchQuery, (_) => _updateSortedRequests(), time: Duration(milliseconds: 300));
    
    // Using `ever` for other changes
    ever(cleaningRequests, (_) => _updateSortedRequests());
    ever(selectedCleaningTypeFilter, (_) => _updateSortedRequests());
    ever(currentUser, (_) => _updateSortedRequests());
    ever(selectedCity, (_) => _updateSortedRequests());
    ever(selectedDistrict, (_) => _updateSortedRequests());
  }

  void updateDistricts(String city) {
    selectedCity.value = city;
    districts.assignAll(Regions.data[city] ?? []);
    selectedDistrict.value = '';
    _updateSortedRequests();
  }

  void updateDistrict(String district) {
    selectedDistrict.value = district;
    _updateSortedRequests();
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

  void _updateSortedRequests() {
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

          return request.targetStaffId == null;
        }).toList();
      } else {
        requests = requests.where((request) {
          return request.targetStaffId == null;
        }).toList();
      }
      

    
    // Region Filtering
    if (selectedCity.value.isNotEmpty) {
      requests = requests.where((request) {
        if (request.address == null) return false;
        if (selectedDistrict.value.isNotEmpty) {
          return request.address!.contains('${selectedCity.value} ${selectedDistrict.value}');
        }
        return request.address!.contains(selectedCity.value);
      }).toList();
    }

    final sortedList = List<CleaningRequest>.from(requests);
    
    // Always sort by created time (Newest first)
    sortedList.sort((a, b) {
      return b.createdAt.compareTo(a.createdAt);
    });
    
    sortedRequests.assignAll(sortedList);
  }
}
