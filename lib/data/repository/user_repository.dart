import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(uid).set(userData);
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      debugPrint('Error getting user: $e');
      rethrow;
    }
  }

  Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking user existence: $e');
      return false;
    }
  }

  Future<bool> userExistsByKakaoId(String kakaoId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('kakaoId', isEqualTo: kakaoId)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
        debugPrint('Error checking user by Kakao ID: $e');
        return false;
    }
  }
}
