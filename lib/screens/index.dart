import 'package:cleanhai2/chatting/chat/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class ApplicationIndex extends StatefulWidget {
  const ApplicationIndex({super.key});

  @override
  State<ApplicationIndex> createState() => _ApplicationIndexState();
}

class _ApplicationIndexState extends State<ApplicationIndex> {

  final _authentication2 = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
        title: Text('everycleaner',style: TextStyle(fontWeight:FontWeight.bold,fontSize: 30),),
        centerTitle: true,
        actions: [IconButton(icon: Icon(
          Icons.exit_to_app_sharp,
          color: Colors.black,
        ),
          onPressed: (){
            _authentication2.signOut();
          },
        )],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: (){
                  },
                  child:
                  Text('청소의뢰목록',
                  style: TextStyle( fontSize:20,fontWeight: FontWeight.w700),
                  ),
                style:ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: (){
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) {
                              return ChatScreen();
                            }
                        )
                    );
                  },
                  child:
                  Text('메세지',
                    style: TextStyle( fontSize:20,fontWeight: FontWeight.w700),
                  ),
                  style:ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[500],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  )
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: (){
                  },
                  child: Text('청소일정등록',
                    style: TextStyle( fontSize:20,fontWeight: FontWeight.bold),
                  ),
                  style:ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  )
              ),
            ),
          ],
        ),
      ),
    );
  }
}
