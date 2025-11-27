import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _controller = TextEditingController();
  var _userEnterMessage = '';
  void _sendMessage () async{
    FocusScope.of(context).unfocus();
    final user = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance.collection('user').doc(user!.uid).get();
    FirebaseFirestore.instance.collection('chat').add({
      'text' : _userEnterMessage,
      'time' : Timestamp.now(),
      'userID' : user!.uid,
      'userName' : userData.data()!['userName'],
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              maxLines: null,
            controller: _controller,
            decoration: InputDecoration(labelText: '메세지를 입력해 주세요'),
            onChanged: (value){
              setState(() {
                _userEnterMessage = value;
              });
            },
          ),
          ),
          IconButton(
              onPressed: _userEnterMessage.trim().isEmpty ? null : _sendMessage,
              icon: Icon(Icons.send),
          color: Colors.blue,
          ),
        ],
      ),
    );
  }
}
