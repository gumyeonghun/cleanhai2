import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cleanhai2/ui/page/main/widgets/main_page.dart';

class AuthController extends GetxController {
  final FirebaseAuth _authentication = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool showSpinner = false.obs;
  final RxBool isSignupScreen = true.obs;
  final RxString userType = 'owner'.obs; // 'owner' or 'staff'
  
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  String userName = '';
  String userEmail = '';
  String userPassword = '';

  void toggleScreenType() {
    isSignupScreen.value = !isSignupScreen.value;
  }

  void setUserType(String type) {
    userType.value = type;
  }

  Future<void> submitForm() async {
    final isValid = formKey.currentState!.validate();
    if (!isValid) return;
    
    formKey.currentState!.save();
    showSpinner.value = true;

    try {
      if (isSignupScreen.value) {
        // Signup Logic
        final newUser = await _authentication.createUserWithEmailAndPassword(
          email: userEmail,
          password: userPassword,
        );

        await _firestore.collection('users').doc(newUser.user!.uid).set({
          'userName': userName,
          'email': userEmail,
          'userType': userType.value,
        });

        if (newUser.user != null) {
          Get.snackbar('성공', '회원가입 성공!', 
            backgroundColor: Colors.green, colorText: Colors.white);
          Get.offAll(() => MainPage());
        }
      } else {
        // Login Logic
        final newUser = await _authentication.signInWithEmailAndPassword(
          email: userEmail,
          password: userPassword,
        );
        
        if (newUser.user != null) {
          Get.offAll(() => MainPage());
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = '알 수 없는 오류가 발생했습니다.';
      
      if (e.code == 'weak-password') {
        message = '비밀번호가 너무 약합니다.';
      } else if (e.code == 'email-already-in-use') {
        message = '이미 사용 중인 이메일입니다.';
      } else if (e.code == 'user-not-found') {
        message = '사용자를 찾을 수 없습니다.';
      } else if (e.code == 'wrong-password') {
        message = '비밀번호가 틀렸습니다.';
      } else if (e.code == 'invalid-email') {
        message = '유효하지 않은 이메일 형식입니다.';
      }

      Get.snackbar(
        '오류', 
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint(e.toString());
      Get.snackbar(
        '오류', 
        '작업을 처리하는 중 오류가 발생했습니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      showSpinner.value = false;
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signInWithGoogle() async {
    try {
      showSpinner.value = true;
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        showSpinner.value = false;
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google User Credential
      final UserCredential userCredential = await _authentication.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // Check if user exists in Firestore
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        
        if (!userDoc.exists) {
          // If user doesn't exist, create a new user document
          // Default to 'owner' type for Google Sign-In, or ask user later
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'userName': userCredential.user!.displayName ?? 'Google User',
            'email': userCredential.user!.email ?? '',
            'userType': 'owner', // Default role
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        
        Get.offAll(() => MainPage());
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      Get.snackbar(
        '오류', 
        'Google 로그인에 실패했습니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      showSpinner.value = false;
    }
  }

  Future<void> signInWithApple() async {
    try {
      showSpinner.value = true;
      
      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an OAuthCredential from the Apple credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple User Credential
      final UserCredential userCredential = await _authentication.signInWithCredential(oauthCredential);
      
      if (userCredential.user != null) {
        // Check if user exists in Firestore
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        
        if (!userDoc.exists) {
          // If user doesn't exist, create a new user document
          String displayName = 'Apple User';
          if (appleCredential.givenName != null && appleCredential.familyName != null) {
            displayName = '${appleCredential.givenName} ${appleCredential.familyName}';
          } else if (userCredential.user!.displayName != null) {
            displayName = userCredential.user!.displayName!;
          }
          
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'userName': displayName,
            'email': userCredential.user!.email ?? appleCredential.email ?? '',
            'userType': 'owner', // Default role
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        
        Get.offAll(() => MainPage());
      }
    } catch (e) {
      debugPrint('Apple Sign-In Error: $e');
      Get.snackbar(
        '오류', 
        'Apple 로그인에 실패했습니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      showSpinner.value = false;
    }
  }
}
