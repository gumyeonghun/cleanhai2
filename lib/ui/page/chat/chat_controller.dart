import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatController extends GetxController {
  final FirebaseAuth _authentication = FirebaseAuth.instance;
  final Rx<User?> loggedUser = Rx<User?>(null);

  @override
  void onInit() {
    super.onInit();
    getCurrentUser();
  }

  void getCurrentUser() {
    try {
      final user = _authentication.currentUser;
      if (user != null) {
        loggedUser.value = user;
      }
    } catch (e) {
      print(e);
    }
  }
}
