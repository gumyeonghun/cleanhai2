import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService extends GetxService {
  final FirebaseAuth _authentication = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Observable for auth state changes if needed elsewhere, 
  // currently we just use direct methods.
  User? get currentUser => _authentication.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _authentication.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _authentication.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      // Optional: await _googleSignIn.disconnect(); 
    } catch (e) {
      debugPrint('Google Sign Out Error (Ignored): $e');
    }
    
    try {
      await _authentication.signOut();
    } catch (e) {
      debugPrint('Firebase Sign Out Error: $e');
      rethrow;
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 기존 로그인 세션 제거하여 계정 선택 화면 강제 표시
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User canceled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _authentication.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // Kakao Sign In
  Future<Map<String, dynamic>?> signInWithKakao() async {
    try {
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          // If cancelled or failed, try account login
           if (error is PlatformException && error.code == 'CANCELED') {
              return null;
          }
          await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      kakao.User user = await kakao.UserApi.instance.me();
      
      // For Kakao, we might need a custom token to sign in to Firebase 
      // or sign in anonymously as done in the original controller.
      // Returning kakao info to controller to decide flow.
      return {
        'kakaoId': user.id.toString(),
        'nickname': user.kakaoAccount?.profile?.nickname,
        'email': user.kakaoAccount?.email,
      };
    } catch (e) {
      debugPrint('Kakao Sign-In Error: $e');
      rethrow;
    }
  }

  Future<UserCredential> signInAnonymously() async {
    return await _authentication.signInAnonymously();
  }

  // Apple Sign In
  Future<UserCredential> signInWithApple() async {
    try {
      final AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          // TODO: Apple Developer Console에서 생성한 Service ID를 입력해주세요.
          // 예: com.gongsunginternational.cleanhai.signin
          clientId: 'com.gongsunginternational.cleanhai.signin', 
          redirectUri: Uri.parse(
            'https://us-central1-cleanhai20092213.cloudfunctions.net/appleSignInCallback',
          ),
        ),
      );

      final OAuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await _authentication.signInWithCredential(credential);
    } catch (e) {
       debugPrint('Apple Sign-In Error: $e');
       rethrow;
    }
  }
}
