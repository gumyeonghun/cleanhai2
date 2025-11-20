import 'package:cleanhai2/chatting/chat/message.dart';
import 'package:cleanhai2/chatting/chat/new_message.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _authentication = FirebaseAuth.instance;
  User? LoggedUser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser(){
    try {
      final user = _authentication.currentUser;
      if (user != null) {
        LoggedUser = user;
        print(LoggedUser!.email);
      }
    }catch(e){
      print(e);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[500],
        title: Text('대화하기', style: TextStyle(color: Colors.white),),
        centerTitle: true,
      ),
      body: Container(
        child: Column(
          children: [
            Expanded(child: Messages(),
            ),
            NewMessage(),
          ],
        ),
      )
    );
  }
}
