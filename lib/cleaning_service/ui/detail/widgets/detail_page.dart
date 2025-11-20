import 'package:cleanhai2/chatting/chat/chat_screen.dart';
import 'package:flutter/material.dart';

import '../../write/widgets/write_page.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Text('대화하기',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
          iconButton(Icons.message, (){
            Navigator.push(context, MaterialPageRoute(builder:
            (context){
              return ChatScreen();
            }
            )
            );
          }),
          iconButton(Icons.delete, (){
            print('삭제 아이콘 터치');
          }),
          iconButton(Icons.edit, (){
            Navigator.push(context, MaterialPageRoute(builder: (context){
              return WritePage();
            }
            )
            );
          }),
        ],
      ),
      body: 
        ListView(
          padding: EdgeInsets.only(bottom: 300),
          children: [
            Image.network('https://picsum.photos/200/300',
            fit: BoxFit.cover,
            ),
            SizedBox(
              height: 15,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('롯데호텔입니다',
                  style: TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 20),
                  ),
                  SizedBox(height: 15,),
                  Text('구명훈',
                  style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 5,),
                  Text('2025.12.25.12:00',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w200
                  ),
                  ),
                  SizedBox(height: 15,),
                  Text('5시부터 3개호실 청소 부탁드립니다'*10,
                    style: TextStyle(fontSize: 15),),
                ],
              ),
            ),
          ],
        )
    );
  }

  Widget iconButton(IconData icon, void Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        child: Container(
          width: 50,
            height: 50,
            color: Colors.transparent,
            child: Icon(icon)
        ),
      )
    );
  }

}
