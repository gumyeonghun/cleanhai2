import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:cleanhai2/data/model/review.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';

class ReviewController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final String requestId;

  ReviewController({required this.requestId});

  final TextEditingController commentController = TextEditingController();
  final RxDouble rating = 5.0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  Future<void> submitReview() async {
    if (commentController.text.trim().isEmpty) {
      Get.snackbar('알림', '후기 내용을 입력해주세요.', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isLoading.value = true;

    try {
      final review = Review(
        rating: rating.value,
        comment: commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _repository.submitReview(requestId, review);
      
      Get.back(); // 페이지 닫기
      Get.snackbar('성공', '소중한 후기가 등록되었습니다.', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('오류', '리뷰 등록 중 오류가 발생했습니다: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
