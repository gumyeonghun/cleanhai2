import 'package:flutter/material.dart';

class TodoNotIndex extends StatelessWidget {
  const TodoNotIndex({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('청소일정',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10)
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AspectRatio(
                        aspectRatio: 2/1,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(fit: BoxFit.cover, 'https://plus.unsplash.com/premium_photo-1684407616444-d52caf1a828f?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1632'))),
                    Spacer(flex: 1,),
                    Text('의뢰한 청소일정이 없습니다', style: TextStyle(fontSize:20, fontWeight: FontWeight.bold, color: Colors.white),),
                    Spacer(flex: 1,),
                    Text('청소일정을 추가하고 청소일정목록에서 일정을 확인해주세요', style: TextStyle(fontSize:16, fontWeight: FontWeight.bold, color: Colors.white),),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),// 청소일정없음 알림박스
    );
  }
}

