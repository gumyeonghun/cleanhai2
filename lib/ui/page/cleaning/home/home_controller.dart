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
    var requests = cleaningRequests;
    
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
      }).toList().obs;
    } else {
      // 검색어가 없을 때도 필터링 적용
      requests = requests.where((request) {
        final user = currentUser.value;
        if (user == null) return request.targetStaffId == null;

        return request.targetStaffId == null || 
               request.targetStaffId == user.id || 
               request.authorId == user.id;
      }).toList().obs;
    }
    
    if (currentUser.value == null || 
        currentUser.value!.latitude == null || 
        currentUser.value!.longitude == null) {
      return requests;
    }

    final userLat = currentUser.value!.latitude!;
    final userLng = currentUser.value!.longitude!;

    final sortedList = List<CleaningRequest>.from(requests);
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
