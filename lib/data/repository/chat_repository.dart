import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../model/chat_room.dart';
import '../model/chat_message.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _chatRoomsRef => _firestore.collection('chat_rooms');

  /// 채팅방 ID 생성 (두 사용자 UID를 정렬하여 조합)
  String getChatRoomId(String uid1, String uid2) {
    List<String> uids = [uid1, uid2]..sort();
    return '${uids[0]}_${uids[1]}';
  }

  Future<ChatRoom> getOrCreateChatRoom(
    String uid1,
    String uid2,
    String name1,
    String name2,
  ) async {
    try {
      final chatRoomId = getChatRoomId(uid1, uid2);
      debugPrint('🔵 채팅방 ID: $chatRoomId');
      debugPrint('🔵 참여자: $uid1, $uid2');
      
      final docRef = _chatRoomsRef.doc(chatRoomId);
      
      // 먼저 채팅방 존재 여부 확인
      DocumentSnapshot? doc;
      try {
        doc = await docRef.get();
        debugPrint('🔵 채팅방 조회 성공: exists=${doc.exists}');
      } catch (e) {
        debugPrint('⚠️ 채팅방 조회 실패 (권한 문제 가능성): $e');
        // 권한 오류인 경우 새로 생성 시도
        doc = null;
      }

      if (doc != null && doc.exists) {
        try {
          return ChatRoom.fromFirestore(doc);
        } catch (e) {
          debugPrint('⚠️ 채팅방 파싱 실패, 재생성 시도: $e');
          // 파싱 실패 시 재생성
        }
      }
      
      // 새 채팅방 생성
      debugPrint('🔵 새 채팅방 생성 시작');
      final newChatRoom = ChatRoom(
        id: chatRoomId,
        participants: [uid1, uid2],
        participantNames: {uid1: name1, uid2: name2},
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      try {
        await docRef.set(newChatRoom.toFirestore());
        debugPrint('✅ 채팅방 생성 성공: $chatRoomId');
        debugPrint('✅ participants: ${newChatRoom.participants}');
        return newChatRoom;
      } catch (e) {
        debugPrint('❌ 채팅방 생성 실패: $e');
        // 생성 실패해도 메모리상의 객체는 반환 (UI는 동작하도록)
        debugPrint('⚠️ 메모리상 채팅방 객체 반환 (Firestore 저장 실패)');
        return newChatRoom;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ getOrCreateChatRoom 전체 실패: $e');
      debugPrint('❌ 스택 트레이스: $stackTrace');
      rethrow;
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

  Future<void> sendMessage(
    String chatRoomId,
    ChatMessage message,
  ) async {
    try {
      debugPrint('🔵 메시지 전송 시작: chatRoomId=$chatRoomId');
      debugPrint('🔵 메시지 내용: ${message.text}');
      debugPrint('🔵 발신자: ${message.senderId} (${message.senderName})');
      
      if (chatRoomId.isEmpty) {
        debugPrint('❌ chatRoomId가 비어있습니다');
        throw Exception('채팅방 ID가 유효하지 않습니다');
      }
      
      final chatRoomRef = _chatRoomsRef.doc(chatRoomId);
      
      // 채팅방 존재 확인
      final chatRoomDoc = await chatRoomRef.get();
      if (!chatRoomDoc.exists) {
        debugPrint('⚠️ 채팅방이 존재하지 않습니다. 새로 생성합니다.');
      }
      
      final messagesRef = chatRoomRef.collection('messages');

      // 메시지 추가
      await messagesRef.add(message.toFirestore());
      debugPrint('✅ 메시지 추가 성공: $chatRoomId');

      // 채팅방의 마지막 메시지 업데이트
      // set with merge:true를 사용하여 문서가 없을 경우에도 생성되도록 함
      await chatRoomRef.set({
        'lastMessage': message.text,
        'lastMessageTime': Timestamp.fromDate(message.timestamp),
      }, SetOptions(merge: true));
      
      debugPrint('✅ 채팅방 업데이트 성공: $chatRoomId, lastMessage: ${message.text}');
    } catch (e, stackTrace) {
      debugPrint('❌ 메시지 전송 실패: $e');
      debugPrint('❌ 스택 트레이스: $stackTrace');
      rethrow; // 에러를 상위로 전파하여 UI에서 처리할 수 있도록 함
    }
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

  /// 채팅 이미지 업로드
  Future<String?> uploadChatImage(File imageFile, String chatRoomId) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('chat_images/$chatRoomId/$fileName');
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('채팅 이미지 업로드 실패: $e');
      return null;
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

  /// 사용자 ID로 모든 채팅방 삭제 (회원 탈퇴용)
  Future<void> deleteAllChatRoomsByUserId(String userId) async {
    try {
      final snapshot = await _chatRoomsRef
          .where('participants', arrayContains: userId)
          .get();
      
      for (var doc in snapshot.docs) {
        // 메시지 서브컬렉션 삭제
        final messagesSnapshot = await doc.reference
            .collection('messages')
            .get();
        
        for (var msgDoc in messagesSnapshot.docs) {
          await msgDoc.reference.delete();
        }
        
        // 채팅방 삭제
        await doc.reference.delete();
      }
      debugPrint('Deleted ${snapshot.docs.length} chat rooms for user $userId');
    } catch (e) {
      debugPrint('Error deleting all chat rooms by user id: $e');
    }
  }
}
