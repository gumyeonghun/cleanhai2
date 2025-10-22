import 'package:flutter/material.dart';

class TodoIndex extends StatelessWidget {
  TodoIndex( {required this.text, this.isDone = false, super.key});

  String text;
  bool isDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 20,),
          Container(
            child: Center(child: Icon(Icons.check, color: Colors.white,size: 20,)),
            width: 25,
            height: 25,
            decoration:BoxDecoration(
              color: isDone? Colors.blue : null,
              border: Border.all(color: Colors.black),
              shape: BoxShape.circle
            ),
          ),
          SizedBox(width: 20,),
          Expanded(child:
          Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          )
          ),
        ],
      )
    );
  }
}
