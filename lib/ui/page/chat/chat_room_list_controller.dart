import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cleanhai2/data/model/chat_room.dart';
import 'package:cleanhai2/data/repository/chat_repository.dart';

class ChatRoomListController extends GetxController {
  final ChatRepository _repository = ChatRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<ChatRoom> chatRooms = <ChatRoom>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadChatRooms();
  }

  void loadChatRooms() {
    final user = _auth.currentUser;
    if (user == null) {
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    _repository.getMyChatRooms(user.uid).listen(
      (rooms) {
        chatRooms.assignAll(rooms);
        isLoading.value = false;
      },
      onError: (error) {
        debugPrint('Error loading chat rooms: $error');
        isLoading.value = false;
      },
    );
  }

  @override
  Future<void> refresh() async {
    loadChatRooms();
  }

  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      await _repository.deleteChatRoom(chatRoomId);
      // 스트림이 자동으로 업데이트하므로 별도의 리로드 필요 없음
      // 하지만 확실하게 하기 위해 로컬 리스트에서도 제거 가능
      chatRooms.removeWhere((room) => room.id == chatRoomId);
      Get.snackbar('알림', '채팅방이 삭제되었습니다.',
          backgroundColor: Colors.black.withValues(alpha: 0.7), colorText: Colors.white);
    } catch (e) {
      Get.snackbar('오류', '채팅방 삭제 중 오류가 발생했습니다.',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
