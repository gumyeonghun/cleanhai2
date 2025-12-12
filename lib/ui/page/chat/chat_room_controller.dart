import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cleanhai2/data/model/chat_room.dart';
import 'package:cleanhai2/data/model/chat_message.dart';
import 'package:cleanhai2/data/repository/chat_repository.dart';

class ChatRoomController extends GetxController {
  final ChatRepository _repository = ChatRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  late final ChatRoom chatRoom;
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isUploadingImage = false.obs;

  void init(ChatRoom room) {
    chatRoom = room;
    loadMessages();
  }

  void loadMessages() {
    isLoading.value = true;
    _repository.getMessages(chatRoom.id).listen((msgs) {
      messages.assignAll(msgs);
      isLoading.value = false;
    });
  }

  Future<void> sendMessage(String text) async {
    final user = _auth.currentUser;
    if (user == null || text.trim().isEmpty) return;

    try {
      // 사용자 이름 가져오기
      final userName = chatRoom.participantNames[user.uid] ?? '알 수 없음';

      final message = ChatMessage(
        id: '',
        text: text.trim(),
        senderId: user.uid,
        senderName: userName,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await _repository.sendMessage(chatRoom.id, message);
    } catch (e) {
      debugPrint('메시지 전송 오류: $e');
      Get.snackbar(
        '오류',
        '메시지 전송에 실패했습니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> pickAndSendImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image == null) return;

      isUploadingImage.value = true;

      // Upload image to Firebase Storage
      final imageUrl = await _repository.uploadChatImage(
        File(image.path),
        chatRoom.id,
      );

      if (imageUrl != null) {
        await sendImageMessage(imageUrl);
      } else {
        Get.snackbar(
          '오류',
          '이미지 업로드에 실패했습니다.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('이미지 선택 오류: $e');
      Get.snackbar(
        '오류',
        '이미지를 선택하는 중 오류가 발생했습니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploadingImage.value = false;
    }
  }

  Future<void> sendImageMessage(String imageUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userName = chatRoom.participantNames[user.uid] ?? '알 수 없음';

    final message = ChatMessage(
      id: '',
      text: '[이미지]',
      senderId: user.uid,
      senderName: userName,
      timestamp: DateTime.now(),
      isRead: false,
      messageType: 'image',
      imageUrl: imageUrl,
    );

    await _repository.sendMessage(chatRoom.id, message);
  }
}
