import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cleanhai2/data/model/report.dart';

class ReportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _reportsRef => _firestore.collection('reports');
  CollectionReference get _usersRef => _firestore.collection('users');

  /// 신고하기 생성
  Future<void> createReport(Report report) async {
    await _reportsRef.add(report.toMap());
  }

  /// 사용자 차단하기 (내 차단 목록에 추가)
  Future<void> blockUser(String myUid, String targetUserId) async {
    // 내 문서의 blocked_users 서브컬렉션에 추가
    await _usersRef.doc(myUid).collection('blocked_users').doc(targetUserId).set({
      'blockedAt': FieldValue.serverTimestamp(),
      'blockedUserId': targetUserId,
    });
  }

  /// 내가 차단한 사용자 목록 가져오기 (ID 리스트)
  Future<List<String>> getBlockedUserIds(String myUid) async {
    try {
      final snapshot = await _usersRef.doc(myUid).collection('blocked_users').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  /// 차단 해제
  Future<void> unblockUser(String myUid, String targetUserId) async {
    await _usersRef.doc(myUid).collection('blocked_users').doc(targetUserId).delete();
  }
}
