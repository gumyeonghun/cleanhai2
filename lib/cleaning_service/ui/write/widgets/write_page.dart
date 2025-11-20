import 'package:flutter/material.dart';

class WritePage extends StatefulWidget {
  const WritePage({super.key});

  @override
  State<WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<WritePage> {

  TextEditingController writeController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    writeController.dispose();
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){FocusScope.of(context).unfocus();},
      child: Scaffold(
        appBar: AppBar(
          actions: [
            GestureDetector(
              onTap: (){
                print('완료 눌러지고 있음');
                formKey.currentState?.validate() ?? false;
              },
              child: Container(
                width: 50,
                height: 50,
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Text('완료',style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 20),
            children: [
              TextFormField(
                controller: writeController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: '작성자'
                ),
                validator: (value){
              if(value?.trim().isEmpty ?? true){
                return '작성자를 입력해 주세요';
              }
              return null;
                }
              ),
              TextFormField(
                controller: titleController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                      hintText: '제목'
                  ),
                  validator: (value){
                    if(value?.trim().isEmpty ?? true){
                      return '제목을 입력해 주세요';
                    }
                    return null;
                  }
              ),
              SizedBox(
                height: 200,
                child: TextFormField(
                  controller: contentController,
                    maxLines: null,
                    expands: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                        hintText: '내용'
                    ),
                    validator: (value){
                      if(value?.trim().isEmpty ?? true){
                        return '내용 입력해 주세요';
                      }
                      return null;
                    }
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey,
                  child: Icon(Icons.image),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
