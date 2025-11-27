import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanhai2/data/model/chat_room.dart';
import 'chat_room_controller.dart';
import 'chat_bubble.dart';

class ChatRoomPage extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatRoomPage({super.key, required this.chatRoom});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _textController = TextEditingController();
  late final ChatRoomController controller;
  String _userEnterMessage = '';

  @override
  void initState() {
    super.initState();
    controller = Get.put(ChatRoomController(), tag: widget.chatRoom.id);
    controller.init(widget.chatRoom);
  }

  @override
  void dispose() {
    _textController.dispose();
    Get.delete<ChatRoomController>(tag: widget.chatRoom.id);
    super.dispose();
  }

  void _sendMessage() async {
    if (_userEnterMessage.trim().isEmpty) return;

    await controller.sendMessage(_userEnterMessage);
    _textController.clear();
    setState(() {
      _userEnterMessage = '';
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final otherUserName = widget.chatRoom.getOtherUserName(myUid);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          otherUserName,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }

              final messages = controller.messages;

              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
                      SizedBox(height: 16),
                      Text(
                        '메시지를 보내 대화를 시작하세요',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                reverse: true,
                padding: EdgeInsets.symmetric(vertical: 16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = message.senderId == myUid;
                  
                  return ChatBubbles(
                    message.text,
                    isMe,
                    message.senderName,
                  );
                },
              );
            }),
          ),

          // Message Input
          Container(
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    maxLines: null,
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력해 주세요',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _userEnterMessage = value;
                      });
                    },
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _userEnterMessage.trim().isEmpty ? null : _sendMessage,
                    icon: Icon(Icons.send),
                    color: Colors.white,
                    disabledColor: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
