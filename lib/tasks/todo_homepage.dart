import 'package:cleanhai2/reservation/reservation.dart';
import 'package:cleanhai2/tasks/todo_index.dart';
import 'package:flutter/material.dart';
import 'package:cleanhai2/tasks/todo_index.dart';
import 'package:cleanhai2/tasks/todo.dart';

class TodoHomepage extends StatefulWidget {
  const TodoHomepage({super.key});

  @override
  State<TodoHomepage> createState() => _TodoHomepageState();
}

class _TodoHomepageState extends State<TodoHomepage> {

  TextEditingController controller = TextEditingController();
  TextEditingController controller2 = TextEditingController();

  List <Todo> todoList = [];

  void onCreate () {
    setState(() {
      Todo newTodo = Todo(title: controller.text,text: controller2.text, isDone: false);
      todoList.add(newTodo);
      controller.clear();
      controller2.clear();
    });
  }

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
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: '청소요청 숙박업소',
                      fillColor: Colors.blue.withValues(alpha: 0.2),
                      filled: true,
                      border:InputBorder.none,
                                ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  TextField(
                    onSubmitted: (value){
                      onCreate();
                    },
                    textInputAction:
                    TextInputAction.done,
                    keyboardType: TextInputType.text
                    ,
                    maxLines: 5,
                    controller: controller2,
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
                   onCreate();
                  },
                      child: Text('청소일정등록',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),))
                  ]
              ),
            )
          );
        }
    );
  } // bottomsheet 영역

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
    controller2.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar:AppBar(
          title: Text('청소일정',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: ListView.separated(
              itemCount: todoList.length,
              separatorBuilder: (context, index){
                return SizedBox(height: 20,);
              },
              itemBuilder: (context, index){
                Todo todo = todoList[index];
                return GestureDetector(
                  onTap: (){
                    setState(() {
                      todo.isDone = !todo.isDone;
                    });
                  },
                  child: TodoIndex(
                    title: todo.title,
                    text: todo.text,
                    isDone: todo.isDone,
                  ),
                );
              }),
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
