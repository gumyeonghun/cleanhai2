import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/chat_room.dart';
import '../model/chat_message.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _chatRoomsRef => _firestore.collection('chat_rooms');

  /// 채팅방 ID 생성 (두 사용자 UID를 정렬하여 조합)
  String getChatRoomId(String uid1, String uid2) {
    List<String> uids = [uid1, uid2]..sort();
    return '${uids[0]}_${uids[1]}';
  }

  /// 채팅방 생성 또는 가져오기
  Future<ChatRoom> getOrCreateChatRoom(
    String uid1,
    String uid2,
    String name1,
    String name2,
  ) async {
    final chatRoomId = getChatRoomId(uid1, uid2);
    final docRef = _chatRoomsRef.doc(chatRoomId);
    final doc = await docRef.get();

    if (doc.exists) {
      return ChatRoom.fromFirestore(doc);
    } else {
      // 새 채팅방 생성
      final newChatRoom = ChatRoom(
        id: chatRoomId,
        participants: [uid1, uid2],
        participantNames: {uid1: name1, uid2: name2},
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await docRef.set(newChatRoom.toFirestore());
      return newChatRoom;
    }
  }

  /// 내 채팅방 목록 조회
  Stream<List<ChatRoom>> getMyChatRooms(String myUid) {
    return _chatRoomsRef
        .where('participants', arrayContains: myUid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc))
          .toList();
    });
  }

  /// 메시지 전송
  Future<void> sendMessage(
    String chatRoomId,
    ChatMessage message,
  ) async {
    final chatRoomRef = _chatRoomsRef.doc(chatRoomId);
    final messagesRef = chatRoomRef.collection('messages');

    // 메시지 추가
    await messagesRef.add(message.toFirestore());

    // 채팅방의 마지막 메시지 업데이트
    await chatRoomRef.update({
      'lastMessage': message.text,
      'lastMessageTime': Timestamp.fromDate(message.timestamp),
    });
  }

  /// 메시지 목록 조회
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    return _chatRoomsRef
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  /// 메시지 읽음 처리
  Future<void> markAsRead(String chatRoomId, String messageId) async {
    try {
      await _chatRoomsRef
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  /// 채팅방 삭제 (선택사항)
  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      // 메시지 서브컬렉션 삭제
      final messagesSnapshot = await _chatRoomsRef
          .doc(chatRoomId)
          .collection('messages')
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // 채팅방 삭제
      await _chatRoomsRef.doc(chatRoomId).delete();
    } catch (e) {
      debugPrint('Error deleting chat room: $e');
    }
  }
}
