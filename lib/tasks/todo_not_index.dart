import 'package:flutter/material.dart';

class TodoNotIndex extends StatelessWidget {
  const TodoNotIndex({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Container(
                  height: 330,
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
                                child: Image.asset(fit:BoxFit.cover, 'image/cleaning.webp'),
                            ),
                        ),
                        SizedBox(height: 20,),
                        Text('의뢰한 청소일정이 없습니다', style: TextStyle(fontSize:20, fontWeight: FontWeight.bold, color: Colors.white),),
                        SizedBox(height: 10,),
                        Text('청소일정을 추가하고 청소일정목록에서 일정을 확인해주세요', style: TextStyle(fontSize:16, fontWeight: FontWeight.bold, color: Colors.white),),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );// 청소일정없음 알림박스
  }
}

