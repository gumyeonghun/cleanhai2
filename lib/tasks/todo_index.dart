import 'package:cleanhai2/tasks/todo_detail.dart';
import 'package:cleanhai2/tasks/todo_not_index.dart';
import 'package:flutter/material.dart';

class TodoIndex extends StatelessWidget {
  TodoIndex( {required this.title, required this.text, this.isDone = false, super.key});

  String title;
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 10,),
          Container(
            child: Center(child: isDone ? Icon(Icons.check, color: Colors.white,size: 20,):null),
            width: 25,
            height: 25,
            decoration:BoxDecoration(
              color: isDone? Colors.blue : null,
              border: Border.all(color: Colors.black),
              shape: BoxShape.circle
            ),
          ),
          SizedBox(width: 10,),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          IconButton(onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context){
                return TodoDetail(text: text,);
              }),
            );
          }, icon: Icon(Icons.dehaze, color: Colors.red,)),
          SizedBox(width: 10,),
        ],
      )
    );
  }
}
