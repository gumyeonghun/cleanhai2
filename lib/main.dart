import 'package:cleanhai2/cleaning_service/ui/home/widgets/home_page.dart';
import 'package:cleanhai2/firebase_options.dart';
import 'package:cleanhai2/screens/index.dart';
import 'package:cleanhai2/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';




void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatting app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple,
        brightness: Brightness.light),
          appBarTheme: AppBarTheme(
            titleTextStyle: TextStyle(
              fontSize: 25,
              color: Colors.blue,
              fontWeight: FontWeight.bold
            ),
          ),


          primarySwatch: Colors.blue
      ),
      home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot){
            if(snapshot.hasData){
              return HomePage();
            } return LoginSignupScreen();
          }
      ),
    );
  }
}