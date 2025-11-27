import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cleanhai2/data/model/chat_room.dart';
import 'chat_room_list_controller.dart';
import 'chat_room_page.dart';

class ChatRoomListPage extends StatelessWidget {
  const ChatRoomListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatRoomListController());
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '채팅',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        final rooms = controller.chatRooms;

        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  '채팅방이 없습니다',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '청소 의뢰 상세 페이지에서\n"대화하기"를 눌러 채팅을 시작하세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView.separated(
            itemCount: rooms.length,
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            itemBuilder: (context, index) => _chatRoomItem(context, rooms[index], myUid),
            separatorBuilder: (context, index) => Divider(height: 1),
          ),
        );
      }),
    );
  }

  Widget _chatRoomItem(BuildContext context, ChatRoom room, String myUid) {
    final otherUserName = room.getOtherUserName(myUid);
    final formattedTime = _formatTime(room.lastMessageTime);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          size: 28,
          color: Colors.white,
        ),
      ),
      title: Text(
        otherUserName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        room.lastMessage.isEmpty ? '채팅을 시작하세요' : room.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Text(
        formattedTime,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[400],
        ),
      ),
      onTap: () {
        Get.to(() => ChatRoomPage(chatRoom: room));
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('MM/dd').format(time);
    }
  }
}
