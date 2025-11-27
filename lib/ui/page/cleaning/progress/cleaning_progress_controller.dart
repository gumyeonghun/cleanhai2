import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/model/progress_note.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';

class CleaningProgressController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final String requestId;
  final bool isStaff; // true: 청소 직원, false: 의뢰자

  CleaningProgressController({
    required this.requestId,
    required this.isStaff,
  });

  final Rx<CleaningRequest?> cleaningRequest = Rx<CleaningRequest?>(null);
  final RxBool isLoading = true.obs;
  final TextEditingController noteController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _bindStream();
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }

  void _bindStream() {
    cleaningRequest.bindStream(_repository.getCleaningRequestStream(requestId));
    ever(cleaningRequest, (_) => isLoading.value = false);
  }

  // 상태 업데이트 (대기중 -> 진행중 -> 완료)
  Future<void> updateStatus(String newStatus) async {
    try {
      await _repository.updateCleaningStatus(requestId, newStatus);
      
      String message = '';
      if (newStatus == 'in_progress') {
        message = '청소가 시작되었습니다.';
      } else if (newStatus == 'completed') {
        message = '청소가 완료되었습니다.';
      }
      
      Get.snackbar('상태 변경', message, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('오류', '상태 변경 중 오류가 발생했습니다: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // 진행 메모 추가
  Future<void> addNote() async {
    if (noteController.text.trim().isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final note = ProgressNote(
        note: noteController.text.trim(),
        createdAt: DateTime.now(),
        createdBy: user.uid,
      );

      await _repository.addProgressNote(requestId, note);
      noteController.clear();
      Get.back(); // 다이얼로그 닫기
      Get.snackbar('메모 추가', '진행 상황이 기록되었습니다.', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('오류', '메모 추가 중 오류가 발생했습니다: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
