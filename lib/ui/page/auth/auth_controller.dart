import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cleanhai2/data/constants/regions.dart';
import 'social_login_setup_page.dart';
import 'package:cleanhai2/ui/page/main/widgets/main_page.dart';
import 'package:cleanhai2/data/repository/user_repository.dart';
import 'package:cleanhai2/service/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final UserRepository _userRepository = Get.find<UserRepository>();

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
  // userLatitude, userLongitude removed
  
  // Region Selection
  final RxString selectedCity = ''.obs;
  final RxString selectedDistrict = ''.obs;
  final RxList<String> districts = <String>[].obs;
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
      if (selectedCity.value.isEmpty || selectedDistrict.value.isEmpty) {
        Get.snackbar('오류', '지역(시/도, 시/구/군)을 모두 선택해주세요.', 
          backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      
      // Construct address for validation check / usage
      userAddress.value = '${selectedCity.value} ${selectedDistrict.value}';
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
        final userCredential = await _authService.signUpWithEmail(userEmail, userPassword);

        debugPrint('회원가입 - 선택된 userType: ${userType.value}');
        
        await _userRepository.createUser(userCredential.user!.uid, {
          'userName': userName,
          'email': userEmail,
          'phoneNumber': phoneNumber,
          'userType': userType.value,
          'address': userAddress.value,
          'detailAddress': detailAddress.value,
          // 'latitude': userLatitude, // Removed
          // 'longitude': userLongitude, // Removed
          'birthDate': Timestamp.fromDate(userBirthDate.value!),
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (userCredential.user != null) {
          Get.snackbar('성공', '회원가입 성공!', 
            backgroundColor: Colors.green, colorText: Colors.white);
          Get.offAll(() => MainPage());
        }
      } else {
        // Login Logic
        final userCredential = await _authService.signInWithEmail(userEmail, userPassword);
        
        if (userCredential.user != null) {
          // Check if user is deleted
          final userDoc = await _userRepository.getUserProfile(userCredential.user!.uid);
          if (userDoc != null && userDoc.isDeleted) {
            await _authService.signOut();
            Get.snackbar('로그인 불가', '탈퇴한 계정입니다.',
              backgroundColor: Colors.red, colorText: Colors.white);
            return;
          }
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

  Future<void> signInWithGoogle() async {
    try {
      showSpinner.value = true;
      
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential == null) {
        // User canceled
        return;
      }
      
      if (userCredential.user != null) {
        // Check if user exists
        final exists = await _userRepository.userExists(userCredential.user!.uid);
        
        if (!exists) {
          // If user doesn't exist, redirect to setup page
          // Pre-fill name and email if available
          userName = userCredential.user!.displayName ?? '';
          userEmail = userCredential.user!.email ?? '';
          Get.to(() => SocialLoginSetupPage());
        } else {
          // Check if user is deleted
          final userDoc = await _userRepository.getUserProfile(userCredential.user!.uid);
          if (userDoc != null && userDoc.isDeleted) {
            await _authService.signOut();
            Get.snackbar('로그인 불가', '탈퇴한 계정입니다.',
              backgroundColor: Colors.red, colorText: Colors.white);
            return;
          }
          Get.offAll(() => MainPage());
        }
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
      
      final kakaoData = await _authService.signInWithKakao();
      
      if (kakaoData == null) {
        return; // Canceled
      }

      String kakaoId = kakaoData['kakaoId'];
      String? nickname = kakaoData['nickname'];
      String? email = kakaoData['email'];

      // Authenticate with Firebase Anonymously
      UserCredential userCredential;
      try {
         userCredential = await _authService.signInAnonymously();
      } catch (e) {
         debugPrint('Anonymous auth failed: $e');
         return;
      }
      
      // Check if this Kakao user already exists in Firestore by Kakao ID
      final exists = await _userRepository.userExistsByKakaoId(kakaoId);

      if (!exists) {
        // Create new user document using the Firebase UID
        await _userRepository.createUser(userCredential.user!.uid, {
          'userName': nickname ?? 'Kakao User',
          'email': email ?? '',
          'userType': 'owner',
          'kakaoId': kakaoId, // Store Kakao ID
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // User exists - check if deleted
        final userDoc = await _userRepository.getUserProfile(userCredential.user!.uid);
        if (userDoc != null && userDoc.isDeleted) {
          await _authService.signOut();
          Get.snackbar('로그인 불가', '탈퇴한 계정입니다.',
            backgroundColor: Colors.red, colorText: Colors.white);
          return;
        }
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

      final userCredential = await _authService.signInWithApple();

      if (userCredential.user != null) {
        final exists = await _userRepository.userExists(userCredential.user!.uid);

        if (!exists) {
          // If user doesn't exist, redirect to setup page
          userName = userCredential.user!.displayName ?? '';
          userEmail = userCredential.user!.email ?? '';
          Get.to(() => SocialLoginSetupPage());
        } else {
          // Check if user is deleted
          final userDoc = await _userRepository.getUserProfile(userCredential.user!.uid);
          if (userDoc != null && userDoc.isDeleted) {
            await _authService.signOut();
            Get.snackbar('로그인 불가', '탈퇴한 계정입니다.',
              backgroundColor: Colors.red, colorText: Colors.white);
            return;
          }
          Get.offAll(() => MainPage());
        }
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

  // Complete Social Signup
  Future<void> completeSocialSignup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('오류', '인증 정보가 없습니다. 다시 로그인해주세요.', 
        backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (userName.isEmpty) {
      Get.snackbar('오류', '이름을 입력해주세요.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (phoneNumber.isEmpty) {
      Get.snackbar('오류', '전화번호를 입력해주세요.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (selectedCity.value.isEmpty || selectedDistrict.value.isEmpty) {
      Get.snackbar('오류', '지역(시/도, 시/구/군)을 모두 선택해주세요.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (userBirthDate.value == null) {
      Get.snackbar('오류', '생년월일을 선택해주세요.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    showSpinner.value = true;
    try {
      // Construct address
      userAddress.value = '${selectedCity.value} ${selectedDistrict.value}';

      await _userRepository.createUser(user.uid, {
        'userName': userName,
        'email': user.email ?? userEmail, // Use Auth email preferably
        'phoneNumber': phoneNumber,
        'userType': userType.value,
        'address': userAddress.value,
        'detailAddress': detailAddress.value,
        'birthDate': Timestamp.fromDate(userBirthDate.value!),
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.offAll(() => MainPage());
      Get.snackbar('환영합니다', '회원가입이 완료되었습니다!', 
        backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      debugPrint('Social Signup Completion Error: $e');
      Get.snackbar('오류', '가입 처리에 실패했습니다: $e', 
        backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      showSpinner.value = false;
    }
  }

  // 주소 업데이트 (KpostalView 사용)
  void updateDistricts(String city) {
    selectedCity.value = city;
    districts.assignAll(Regions.data[city] ?? []);
    selectedDistrict.value = '';
    // _updateAddressString();
  }

  void updateDistrict(String district) {
    selectedDistrict.value = district;
    // _updateAddressString();
  }
  
  /*
  void _updateAddressString() {
    if (selectedCity.value.isNotEmpty && selectedDistrict.value.isNotEmpty) {
      userAddress.value = '${selectedCity.value} ${selectedDistrict.value}';
    }
  }
  */
}
