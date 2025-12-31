import 'package:cleanhai2/firebase_options.dart';
import 'package:cleanhai2/ui/page/main/widgets/main_page.dart';
import 'package:cleanhai2/ui/page/auth/login_signup_page.dart';

import 'package:cleanhai2/data/repository/user_repository.dart';
import 'package:cleanhai2/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Add your Kakao Native App Key here
  // KakaoSdk.init(nativeAppKey: 'YOUR_NATIVE_APP_KEY');
  
  // Parallel initialization for faster startup
  await Future.wait([
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
    ),
    // Add other async initializers here if needed
  ]);
  
  // Dependency Injection
  Get.put(UserRepository());
  Get.put(AuthService());

  // Get.put(InterstitialAdController());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      title: '청소혁명가',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF1E88E5), // Trustworthy Blue
          primary: Color(0xFF1E88E5),
          secondary: Color(0xFF64B5F6),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold
          ),
        ),
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return MainPage();
          }
          return LoginSignupPage();
        }
      ),
    );
  }
}