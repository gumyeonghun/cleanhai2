import 'package:cleanhai2/cleaning_service/ui/write/widgets/write_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../detail/widgets/detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //리스트 뷰 목록에 표시되는 각각의 컨텐츠
    Widget item ({required String? title, required String? content}){
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: (){
            Navigator.push(context, MaterialPageRoute(builder:
            (context){
              return DetailPage();
            }
            )
            );
          },
          child: Container(
            width: double.infinity,
            height: 120,
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  child:ClipRRect(
                      borderRadius: BorderRadius.circular(0),
                      child: Image.network('https://picsum.photos/200/300',
                        fit: BoxFit.cover,
                      )),
                ),
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: EdgeInsets.only(right: 100),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title!,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                        Spacer(),
                        Text(content!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),),
                        SizedBox(height: 5,),
                        Text('2025.12.25.12:00',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold
                          ),),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  final _authentication3 = FirebaseAuth.instance;
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[500],
      appBar: AppBar(
        title:Text('청소5분대기조'),
        centerTitle: true,
        leading: IconButton(onPressed: (){
          _authentication3.signOut();
        },
            icon: Icon(Icons.exit_to_app_outlined)),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: (){
            Navigator.push(context,
                MaterialPageRoute(builder: (context){
              return WritePage();
            }
            )
            );
          },
        child: Icon(Icons.edit),
      ),
      body: IndexedStack(
        index: index,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('최근글',
                style: TextStyle(
                  fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20,),
                Expanded(
                  child: ListView.separated(
                    itemCount: 10,
                    itemBuilder: (context, index) => item(
                      title: '롯데호텔입니다',
                      content: '금일 5시부터 3개호실 청소해 주실분 구합니다',
                    ),
                    separatorBuilder: (context, index) => SizedBox(height: 15),
                  ),
                ),
              ],
            ),
          ),
          // 청소의뢰 및 홈페이지
          Container(
            color: Colors.blue[100],
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('최근글',
                    style: TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20,),
                  Expanded(
                    child: ListView.separated(
                      itemCount: 10,
                      itemBuilder: (context, index) => item(
                        title: '20년차 가정주부입니다',
                        content: '어떤 청소든지 자신있습니다',
                      ),
                      separatorBuilder: (context, index) => SizedBox(height: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 청소대기 페이지
          Container(color: Colors.blue,)
          //청소일정확인 페이지
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        iconSize: 30,
        selectedFontSize: 15,
        unselectedFontSize: 15,
        currentIndex: index,
        onTap: (value){
          print(value);
          setState(() {
            index = value;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '청소의뢰',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '청소대기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: '내청소일정',
          ),
        ],
      ),
    );
  }
}
