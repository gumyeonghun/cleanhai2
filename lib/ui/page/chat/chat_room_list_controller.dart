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
}
