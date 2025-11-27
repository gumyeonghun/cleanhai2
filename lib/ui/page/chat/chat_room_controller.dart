import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanhai2/data/model/chat_room.dart';
import 'package:cleanhai2/data/model/chat_message.dart';
import 'package:cleanhai2/data/repository/chat_repository.dart';

class ChatRoomController extends GetxController {
  final ChatRepository _repository = ChatRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final ChatRoom chatRoom;
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = true.obs;

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
  }
}
