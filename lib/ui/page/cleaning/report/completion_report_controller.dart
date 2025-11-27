import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cleanhai2/data/model/completion_report.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';

class CompletionReportController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final String requestId;

  CompletionReportController({required this.requestId});

  final TextEditingController summaryController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  final RxList<XFile> selectedImages = <XFile>[].obs;
  final RxBool isLoading = false.obs;
  final ImagePicker _picker = ImagePicker();

  @override
  void onClose() {
    summaryController.dispose();
    detailsController.dispose();
    super.onClose();
  }

  Future<void> pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      selectedImages.addAll(images);
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  Future<void> submitReport() async {
    if (summaryController.text.trim().isEmpty || detailsController.text.trim().isEmpty) {
      Get.snackbar('알림', '요약과 상세 내용을 모두 입력해주세요.', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isLoading.value = true;

    try {
      List<String> imageUrls = [];
      
      // 이미지 업로드
      for (var image in selectedImages) {
        String? url = await _repository.uploadImage(File(image.path), 'completion_report');
        if (url != null) {
          imageUrls.add(url);
        }
      }

      final report = CompletionReport(
        summary: summaryController.text.trim(),
        details: detailsController.text.trim(),
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
      );

      await _repository.submitCompletionReport(requestId, report);
      
      Get.back(); // 페이지 닫기
      Get.snackbar('성공', '청소 완료 보고서가 제출되었습니다.', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('오류', '보고서 제출 중 오류가 발생했습니다: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
