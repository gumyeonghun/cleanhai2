import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';

class MyScheduleController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<CleaningRequest> myAcceptedRequests = <CleaningRequest>[].obs;
  final RxList<CleaningRequest> myAppliedRequests = <CleaningRequest>[].obs;
  final RxBool isLoading = true.obs;
  
  // 이전에 확인한 요청 ID들을 저장
  final RxList<String> _previousAcceptedIds = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMySchedule();
  }

  void loadMySchedule() {
    final user = _auth.currentUser;
    if (user == null) {
      isLoading.value = false;
      return;
    }

    // 의뢰자: 내가 의뢰한 것 중 수락된 것
    _repository.getMyAcceptedRequestsAsOwner(user.uid).listen((requests) {
      myAcceptedRequests.assignAll(requests);
    });

    // 청소 직원: 내가 신청한 모든 의뢰
    _repository.getMyAppliedRequestsAsStaff(user.uid).listen((requests) {
      // 새로 수락된 요청 확인
      final acceptedRequests = requests.where((r) => r.status == 'accepted').toList();
      final newAcceptedIds = acceptedRequests.map((r) => r.id).toSet();
      
      // 이전에 없던 새로운 매칭 확인
      if (_previousAcceptedIds.isNotEmpty) {
        final newMatches = newAcceptedIds.difference(_previousAcceptedIds.toSet());
        if (newMatches.isNotEmpty) {
          // 새로운 매칭이 있으면 알림 표시
          for (var requestId in newMatches) {
            final request = acceptedRequests.firstWhere((r) => r.id == requestId);
            Get.snackbar(
              '매칭 완료!',
              '${request.authorName}님의 청소 의뢰가 수락되었습니다!\n일정을 확인해주세요.',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: Duration(seconds: 5),
              snackPosition: SnackPosition.TOP,
              icon: Icon(Icons.check_circle, color: Colors.white),
            );
          }
        }
      }
      
      // 현재 수락된 요청 ID 저장
      _previousAcceptedIds.assignAll(newAcceptedIds.toList());
      
      myAppliedRequests.assignAll(requests);
      isLoading.value = false;
    });
  }

  @override
  Future<void> refresh() async {
    loadMySchedule();
  }
}
