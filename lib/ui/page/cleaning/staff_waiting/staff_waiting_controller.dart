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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isFabExpanded = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
    loadWaitingStaff();
  }

  Future<void> loadUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      currentUser.value = await _repository.getUserProfile(user.uid);
    }
  }

  List<CleaningStaff> get sortedStaff {
    if (currentUser.value == null || 
        currentUser.value!.latitude == null || 
        currentUser.value!.longitude == null) {
      return waitingStaff;
    }

    final userLat = currentUser.value!.latitude!;
    final userLng = currentUser.value!.longitude!;

    final sortedList = List<CleaningStaff>.from(waitingStaff);
    sortedList.sort((a, b) {
      if (a.latitude == null || a.longitude == null) return 1;
      if (b.latitude == null || b.longitude == null) return -1;

      final distA = LocationUtils.calculateDistance(userLat, userLng, a.latitude!, a.longitude!);
      final distB = LocationUtils.calculateDistance(userLat, userLng, b.latitude!, b.longitude!);

      return distA.compareTo(distB);
    });
    
    return sortedList;
  }

  Future<void> loadWaitingStaff() async {
    isLoading.value = true;
    try {
      final staff = await _repository.getWaitingStaff();
      waitingStaff.assignAll(staff);
    } catch (e) {
      debugPrint('Error loading waiting staff: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    await loadWaitingStaff();
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
