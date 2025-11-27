import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_6.dart';

class ChatBubbles extends StatelessWidget {
  const ChatBubbles (this.message, this.isMe, this.userName, {super.key});

  final String message;
  final String userName;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if(isMe)
          Padding(
            padding: const EdgeInsets.fromLTRB(0,0,10,0),
            child: ChatBubble(
              clipper: ChatBubbleClipper6(type: BubbleType.sendBubble),
              alignment: Alignment.topRight,
              margin: EdgeInsets.only(top: 20),
              backGroundColor: Colors.blue,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(userName,
                      style: TextStyle(fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(message,
                      style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if(!isMe)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: ChatBubble(
              clipper: ChatBubbleClipper6(type: BubbleType.receiverBubble),
              backGroundColor: Color(0xffE7E7ED),
              margin: EdgeInsets.only(top: 20),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                    style: TextStyle(fontWeight: FontWeight.bold,),
                    ),
                    Text(message,
                      style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          )
      ],
    );
  }
}
