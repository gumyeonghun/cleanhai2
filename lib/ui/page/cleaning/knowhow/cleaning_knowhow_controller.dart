import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cleanhai2/data/model/cleaning_knowhow.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CleaningKnowhowController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // List State
  final RxList<CleaningKnowhow> knowhows = <CleaningKnowhow>[].obs;
  final RxBool isLoading = false.obs;

  // Write State
  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxBool isUploading = false.obs;
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _bindKnowhows();
  }

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    super.onClose();
  }

  void _bindKnowhows() {
    isLoading.value = true;
    _repository.getKnowhows().listen((list) {
      knowhows.assignAll(list);
      isLoading.value = false;
    });
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImage.value = File(image.path);
    }
  }

  void clearWriteForm() {
    selectedImage.value = null;
    titleController.clear();
    contentController.clear();
  }

  Future<void> createKnowhow() async {
    if (titleController.text.isEmpty || contentController.text.isEmpty) {
      Get.snackbar('알림', '제목과 내용을 입력해주세요.');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar('오류', '로그인이 필요합니다.');
      return;
    }

    isUploading.value = true;
    try {
      // Fetch user profile to get name
      final userProfile = await _repository.getUserProfile(user.uid);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      String? imageUrl;
      if (selectedImage.value != null) {
        imageUrl = await _repository.uploadImage(selectedImage.value!, 'knowhow');
      }

      final newKnowhow = CleaningKnowhow(
        id: '', // Firestore generates ID
        title: titleController.text,
        content: contentController.text,
        authorId: user.uid,
        authorName: userProfile.userName ?? '익명',
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      await _repository.createKnowhow(newKnowhow);
      Get.back(); // Close write page
      Get.snackbar('성공', '노하우가 등록되었습니다.');
      clearWriteForm();
    } catch (e) {
      Get.snackbar('오류', '등록 중 문제가 발생했습니다: $e');
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> deleteKnowhow(String id) async {
    try {
      await _repository.deleteKnowhow(id);
      Get.back(); // Close detail page if open
      Get.snackbar('삭제', '노하우가 삭제되었습니다.');
    } catch (e) {
      Get.snackbar('오류', '삭제 중 문제가 발생했습니다: $e');
    }
  }
}
