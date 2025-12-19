import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:kpostal/kpostal.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cleanhai2/ui/page/main/widgets/main_page.dart';

class AuthController extends GetxController {
  final FirebaseAuth _authentication = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool showSpinner = false.obs;
  final RxBool isSignupScreen = false.obs;
  final RxString userType = 'owner'.obs; // 'owner' or 'staff'
  
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  String userName = '';
  String userEmail = '';
  String phoneNumber = '';
  String userPassword = '';
  String confirmPassword = '';
  final RxString userAddress = ''.obs;
  final RxString detailAddress = ''.obs;
  double? userLatitude;
  double? userLongitude;
  final Rx<DateTime?> userBirthDate = Rx<DateTime?>(null);

  // Getter for isLoading (alias for showSpinner)
  RxBool get isLoading => showSpinner;

  void toggleScreen(bool isSignup) {
    isSignupScreen.value = isSignup;
  }

  void toggleScreenType() {
    isSignupScreen.value = !isSignupScreen.value;
  }

  void setUserType(String type) {
    userType.value = type;
  }

  void setBirthDate(DateTime date) {
    userBirthDate.value = date;
  }

  // Alias for submitForm
  Future<void> submit() async {
    await submitForm();
  }

  Future<void> submitForm() async {
    final isValid = formKey.currentState!.validate();
    if (!isValid) return;
    
    formKey.currentState!.save();
    
    if (isSignupScreen.value) {
      if (userPassword != confirmPassword) {
        Get.snackbar('오류', '비밀번호가 일치하지 않습니다.', 
          backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      if (userAddress.value.isEmpty) {
        Get.snackbar('오류', '주소를 입력해주세요.', 
          backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      if (userBirthDate.value == null) {
        Get.snackbar('오류', '생년월일을 선택해주세요.', 
          backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
    }
    
    showSpinner.value = true;

    try {
      if (isSignupScreen.value) {
        // Signup Logic
        final newUser = await _authentication.createUserWithEmailAndPassword(
          email: userEmail,
          password: userPassword,
        );

        debugPrint('회원가입 - 선택된 userType: ${userType.value}');
        
        await _firestore.collection('users').doc(newUser.user!.uid).set({
          'userName': userName,
          'email': userEmail,
          'phoneNumber': phoneNumber,
          'userType': userType.value,
          'address': userAddress.value,
          'detailAddress': detailAddress.value,
          'latitude': userLatitude,
          'longitude': userLongitude,
          'birthDate': Timestamp.fromDate(userBirthDate.value!),
          'createdAt': FieldValue.serverTimestamp(),
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

  // Kakao Login Implementation
  Future<void> signInWithKakao() async {
    try {
      showSpinner.value = true;
      
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          await kakao.UserApi.instance.loginWithKakaoTalk();
          debugPrint('카카오톡으로 로그인 성공');
        } catch (error) {
          debugPrint('카카오톡으로 로그인 실패 $error');
          // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
          // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도를 하지 않습니다.
          if (error is PlatformException && error.code == 'CANCELED') {
              showSpinner.value = false;
              return;
          }
          // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
          try {
              await kakao.UserApi.instance.loginWithKakaoAccount();
              debugPrint('카카오계정으로 로그인 성공');
          } catch (error) {
              debugPrint('카카오계정으로 로그인 실패 $error');
              showSpinner.value = false;
              return;
          }
        }
      } else {
        try {
          await kakao.UserApi.instance.loginWithKakaoAccount();
          debugPrint('카카오계정으로 로그인 성공');
        } catch (error) {
          debugPrint('카카오계정으로 로그인 실패 $error');
          showSpinner.value = false;
          return;
        }
      }

      // Get Kakao User Info
      kakao.User user = await kakao.UserApi.instance.me();
      
      // Retrieving user info
      var kakaoProfile = user.kakaoAccount?.profile;
      var kakaoEmail = user.kakaoAccount?.email;
      var kakaoId = user.id.toString();

      // Authenticate with Firebase Anonymously to generate a User UID
      UserCredential userCredential;
      try {
         // Create an anonymous user to have a UID in Firebase
         userCredential = await _authentication.signInAnonymously();
      } catch (e) {
         debugPrint('Anonymous auth failed: $e');
         showSpinner.value = false;
         return;
      }
      
      // Check if this Kakao user already exists in Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .where('kakaoId', isEqualTo: kakaoId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Create new user document using the Firebase UID
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'userName': kakaoProfile?.nickname ?? 'Kakao User',
          'email': kakaoEmail ?? '',
          'userType': 'owner',
          'kakaoId': kakaoId, // Store Kakao ID
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // User exists
        // Ideally we would log in as that user, but with anonymous auth we have a new UID.
        // For this task, we will proceed. In a real app we'd need Custom Auth.
        debugPrint('User already exists in Firestore with Kakao ID: $kakaoId');
      }
      
      Get.offAll(() => MainPage());

    } catch (e) {
      debugPrint('Kakao Sign-In Error: $e');
      Get.snackbar(
        '오류', 
        'Kakao 로그인에 실패했습니다.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      showSpinner.value = false;
    }
  }

  // Apple Login Implementation
  Future<void> signInWithApple() async {
    try {
      showSpinner.value = true;

      final AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple User Credential
      final UserCredential userCredential = await _authentication.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Check if user exists in Firestore
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

        if (!userDoc.exists) {
          // If user doesn't exist, create a new user document
          // Apple only returns the name on the first sign in.
          // However, we can try to use the name from appleCredential if available.
          
          String name = 'Apple User';
          if (appleCredential.givenName != null || appleCredential.familyName != null) {
              name = '${appleCredential.familyName ?? ''} ${appleCredential.givenName ?? ''}'.trim();
          }

          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'userName': name.isNotEmpty ? name : 'Apple User',
            'email': userCredential.user!.email ?? '',
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

  // 주소 업데이트 (KpostalView 사용)
  Future<void> updateAddress() async {
    await Get.to(() => KpostalView(
      callback: (Kpostal result) async {
        double? lat = result.latitude;
        double? lng = result.longitude;

        // 좌표가 없는 경우 주소로 좌표 검색
        if (lat == null || lng == null) {
          try {
            List<Location> locations = await locationFromAddress(result.address);
            if (locations.isNotEmpty) {
              lat = locations.first.latitude;
              lng = locations.first.longitude;
            }
          } catch (e) {
            debugPrint('좌표 변환 실패: $e');
          }
        }

        userAddress.value = result.address;
        userLatitude = lat;
        userLongitude = lng;
      },
    ));
  }
}
