import 'package:flutter/material.dart';

class TodoDetail extends StatelessWidget {
  TodoDetail({required this.text, super.key});

  String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("청소요청사항",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,letterSpacing: 2),),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Container(
          child: Text(text),
        ),
      ),
    );
  }
}
