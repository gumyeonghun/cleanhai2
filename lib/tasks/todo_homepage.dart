import 'package:cleanhai2/reservation/reservation.dart';
import 'package:cleanhai2/tasks/todo_index.dart';
import 'package:flutter/material.dart';
import 'package:cleanhai2/tasks/todo_index.dart';

class TodoHomepage extends StatefulWidget {
  const TodoHomepage({super.key});

  @override
  State<TodoHomepage> createState() => _TodoHomepageState();
}

class _TodoHomepageState extends State<TodoHomepage> {

  TextEditingController nameController = TextEditingController();
  TextEditingController detailController = TextEditingController();


  void update ()async{

    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context){
          return SizedBox(
            width: double.infinity,
            height: 500,
            child: Padding(
                padding: EdgeInsets.only(
              top: 30,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom
                ),
              child: ListView(
                children: [
                  TextField(
                    textInputAction:
                    TextInputAction.done,
                    keyboardType: TextInputType.text,
                    maxLines: 1,
                    controller: nameController,
                    decoration: InputDecoration(
                      fillColor: Colors.blue.withValues(alpha: 0.2),
                      filled: true,
                      border:InputBorder.none,
                      hintText: '청소의뢰자'
                                ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  TextField(
                    onSubmitted: (value){},
                    textInputAction:
                    TextInputAction.done,
                    keyboardType: TextInputType.text
                    ,
                    maxLines: 10,
                    controller: detailController,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.black,
                              width: 3.0
                          ),
                        ),
                        hintText: '청소요청사항'
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[100],
                      ),
                      onPressed: (){
                        print(nameController.text);
                        print(detailController.text);
                  },
                      child: Text('청소일정등록',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),))
                  ]
              ),
            )
          );
        }
    );
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    detailController.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar:AppBar(
          title: Text('청소의뢰하기',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
        body:
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: ListView(
            children: [
              TodoIndex(text: '1',isDone: false,),
              SizedBox(height: 20),
              TodoIndex(text:'dfasdf', isDone : true),
              SizedBox(height: 20,),
              Container(
                height: 300,
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
              ),// 청소일정없음 알림박스
            ],
          ),
        ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              height: 65,
              width: 65,
              child: FloatingActionButton(
                backgroundColor: Colors.blue,
                  child: Icon(Icons.add, color: Colors.white, size: 30,),
                  onPressed: (){
                  update();
                  }
                  ),
            ),
          ),
      ),
    );
  }
}
