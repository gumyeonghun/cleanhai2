
import 'package:flutter/material.dart';
import 'package:cleanhai2/config/palette.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final _auhthentication = FirebaseAuth.instance;

  bool showSpinner = false;
  bool isSignupScreen = true;
  final _formKey = GlobalKey<FormState>();
  String userName = '';
  String userEmail = '';
  String userPassword = '';

  void _tryValidation(){
    final isValid = _formKey.currentState!.validate();
    if(isValid){
      _formKey.currentState!.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.backgroundColor,
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: GestureDetector(
          onTap: (){
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              Positioned(
                  top: 0,
                  right: 0,
                  left: 0,
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.blue
                    ),
                    child: Container(
                      padding: EdgeInsets.only(top: 120,left: 20,right: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                            text: 'Welcome Korea NO.1 Cleaning service ',
                            style: TextStyle(
                                letterSpacing: 1.0,
                                fontSize: 25,
                                color: Colors.white
                            ),
                            children: [
                              TextSpan(
                                text:'청소5분대기조',
                                style: TextStyle(
                                    letterSpacing: 2.0,
                                    fontSize: 40,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  )
              ),
              // 배경
              AnimatedPositioned(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeIn,
                  top: 250,
                  child:
                  AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeIn,
                    padding: EdgeInsets.all(20),
                    height: isSignupScreen ? 335 : 270,
                    width: MediaQuery.of(context).size.width-40,
                    margin: EdgeInsets.symmetric(horizontal: 20.0),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 10,
                        )
                        ]
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: 50),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              GestureDetector(
                                onTap: (){
                                  setState(() {
                                    isSignupScreen = false;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Text('Login',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: !isSignupScreen ? Palette.activeColor : Palette.textColor1,
                                      ),
                                    ),
                                    if(!isSignupScreen)
                                      Container(
                                        margin: EdgeInsets.only(top: 10),
                                        height: 2,
                                        width: 55,
                                        color: Colors.orange,
                                      )
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: (){
                                  setState(() {
                                    isSignupScreen = true;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Text('Signup',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isSignupScreen ? Palette.activeColor : Palette.textColor1,
                                      ),
                                    ),
                                    if(isSignupScreen)
                                      Container(
                                        margin: EdgeInsets.only(top: 10),
                                        height: 2,
                                        width: 55,
                                        color: Colors.orange,
                                      )
                                  ],
                                ),
                              )
                            ],
                          ),
                          if(isSignupScreen)
                            Container(
                              margin: EdgeInsets.only(top: 20),
                              child: Form(
                                  key: _formKey,
                                  child:Column(
                                    children: [
                                      TextFormField(
                                        key : ValueKey(1),
                                        validator: (value){
                                          if(value!.isEmpty){
                                            return '글자를 입력해 주세요';
                                          }
                                          return null;
                                        },
                                        onSaved: (value){
                                          userName = value!;
                                        },
                                        onChanged: (value){
                                          userName = value;
                                        } ,
                                        decoration: InputDecoration(
                                            prefixIcon: Icon(
                                              Icons.account_circle,
                                              color: Palette.iconColor,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Palette.textColor1
                                                ),
                                                borderRadius: BorderRadius.all(Radius.circular(35))
                                            ),
                                            focusedBorder:
                                            OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Palette.textColor1
                                                ),
                                                borderRadius: BorderRadius.all(Radius.circular(35))
                                            ),
                                            hintText:'이름을 입력해 주세요',
                                            hintStyle: TextStyle(
                                                fontSize: 17,
                                                color: Palette.textColor1
                                            ),
                                            contentPadding: EdgeInsets.all(10)
                                        ),
                                      ),
                                      SizedBox(
                                        height: 15,
                                      ),
                                      TextFormField(
                                        obscureText: true,
                                        key: ValueKey(2),
                                        validator: (value){
                                          if(value!.isEmpty || value.length < 6){
                                            return '6자이상 입력해 주세요';
                                          }
                                          return null;
                                        },
                                        onSaved: (value){
                                          userPassword = value!;
                                        },
                                        onChanged: (value){
                                          userPassword = value;
                                        },
                                        decoration: InputDecoration(
                                            prefixIcon: Icon(
                                              Icons.password,
                                              color: Palette.iconColor,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide:
                                              BorderSide(color: Palette.textColor1),
                                              borderRadius: BorderRadius.all(Radius.circular(35),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide:
                                              BorderSide(color: Palette.textColor1),
                                              borderRadius: BorderRadius.all(Radius.circular(35),
                                              ),
                                            ),
                                            hintText: '비밀번호 입력해 주세요',
                                            hintStyle: TextStyle(
                                                fontSize: 17,
                                                color: Palette.textColor1
                                            ),
                                            contentPadding: EdgeInsets.all(10)
                                        ),
                                      ),
                                      SizedBox(
                                        height: 15,
                                      ),
                                      TextFormField(
                                        keyboardType: TextInputType.emailAddress,
                                        key: ValueKey(3),
                                        validator: (value){
                                          if (value!.isEmpty || !value.contains('@'))
                                          {return '이메일 형식에 맞추어 입력해 주세요';
                                          }
                                          return null;
                                        },
                                        onSaved: (value){
                                          userEmail = value!;
                                        },
                                        onChanged: (value){
                                          userEmail = value;
                                        },
                                        decoration: InputDecoration(
                                            prefixIcon: Icon(Icons.email,
                                              color: Palette.iconColor,),
                                            enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: Palette.textColor1),
                                                borderRadius: BorderRadius.all(Radius.circular(35))
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: Palette.textColor1),
                                                borderRadius: BorderRadius.all(Radius.circular(35))
                                            ),
                                            hintText: 'E-mail을 입력해 주세요',
                                            hintStyle: TextStyle(
                                                fontSize: 17,
                                                color: Palette.textColor1
                                            ),
                                            contentPadding: EdgeInsets.all(10)
                                        ),
                                      )
                                    ],
                                  )
                              ),
                            ),
                          if (!isSignupScreen)
                            Container(
                              margin: EdgeInsets.only(top: 20.0),
                              child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        validator: (value){
                                          if(value!.isEmpty || !value.contains('@'))
                                          {
                                            return '이메일 형식에 맞추어 입력해 주세요';
                                          }
                                          return null;
                                        },
                                        onSaved: (value){
                                          userEmail = value!;
                                        },
                                        onChanged: (value){
                                          userEmail = value;
                                        },
                                        key : ValueKey(4),
                                        decoration: InputDecoration(
                                            prefixIcon: Icon(
                                              Icons.email,
                                              color: Palette.iconColor,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide:
                                              BorderSide(
                                                  color: Palette.textColor1),
                                              borderRadius: BorderRadius.all(Radius.circular(35.0),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide:
                                              BorderSide(
                                                  color: Palette.textColor1),
                                              borderRadius: BorderRadius.all(Radius.circular(35.0),
                                              ),
                                            ),
                                            hintText: 'E-mail을 입력해 주세요',
                                            hintStyle: TextStyle(
                                                fontSize: 15,
                                                color: Palette.textColor1
                                            ),
                                            contentPadding: EdgeInsets.all(10)
                                        ),
                                      ),
                                      SizedBox(
                                        height: 15,
                                      ),
                                      TextFormField(
                                        obscureText: true,
                                        key: ValueKey(5),
                                        validator: (value){
                                          if(value!.isEmpty || value.length < 6){
                                            return '6자이상 입력해 주세요';
                                          }
                                          return null;
                                        },
                                        onSaved: (value){
                                          userPassword = value!;
                                        },
                                        onChanged: (value){
                                          userPassword = value;
                                        },
                                        decoration: InputDecoration(
                                            prefixIcon: Icon(
                                              Icons.password,
                                              color: Palette.iconColor,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide:
                                              BorderSide(
                                                  color: Palette.textColor1),
                                              borderRadius: BorderRadius.all(Radius.circular(35.0),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide:
                                              BorderSide(
                                                  color: Palette.textColor1),
                                              borderRadius: BorderRadius.all(Radius.circular(35.0),
                                              ),
                                            ),
                                            hintText: '비밀번호를 입력해 주세요',
                                            hintStyle: TextStyle(
                                                fontSize: 15,
                                                color: Palette.textColor1
                                            ),
                                            contentPadding: EdgeInsets.all(10)
                                        ),
                                      ),
                                    ],
                                  )
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
              ),
              // 텍스트 폼 필드
              AnimatedPositioned(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeIn,
                top: isSignupScreen ? 540 : 470,
                right: 0,
                left: 0,
                child:Center(
                  child: Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50)
                    ),
                    child: GestureDetector(
                      onTap: () async{
                        setState(() {
                          showSpinner = true;
                        });
                       if(isSignupScreen){
                        _tryValidation();
        
                        try {
                          final newUser = await _auhthentication.createUserWithEmailAndPassword(
                              email: userEmail,
                              password: userPassword,
                          );
                          
                          await FirebaseFirestore.instance.collection('user').doc(newUser.user!.uid)
                              .set({
                            'userName' : userName,
                            'email' : userEmail
                          });
        
                          if(newUser.user != null){
                            // Navigator.push(
                            //     context,
                            //     MaterialPageRoute(builder: (context){
                            //       return ChatScreen();
                            //     })
                            // );
                            setState(() {
                              showSpinner = false;
                            });
                          }
                        } catch(e) {
                          print(e);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('입력한 정보를 확인 해주세요'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                          setState(() {
                            showSpinner = false;
                          });
                        }
                       }
                          if(!isSignupScreen){
                            _tryValidation();
                            try {
                              final newUser =
                              await _auhthentication.signInWithEmailAndPassword(
                                  email: userEmail,
                                  password: userPassword);
                              if (newUser.user != null) {
                                // Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //         builder: (context) {
                                //           return ChatScreen();
                                //         }
                                //     )
                                // );
                              }
                            } catch(e){
                              print(e);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('E-mail과 비밀번호를 확인 해주세요'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                              setState(() {
                                showSpinner = false;
                              });
                            }
                          }
                        },
                      child: Container(
                        margin: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors:[
                                Colors.orange,
                                Colors.red
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow:[ BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 1,
                              offset: Offset(0, 1)
                          ),
                          ],
                        ),
                        child: Icon(Icons.arrow_forward,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 전송버튼

              Positioned(
                  top: MediaQuery.of(context).size.height-280,
                  right: 0,
                  left: 0,
                  child: Column(
                    children: [
                      Container(
                        child: Text(
                          isSignupScreen ? '회원가입을 해 주세요':'로그인을 해 주세요',
                          style: TextStyle(
                            letterSpacing: 1.0,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                      SizedBox(height: 20,),
                      Text(isSignupScreen ? 'or Signup with' : ' or Signin with',
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      TextButton.icon(
                        onPressed: (){},
                        style: TextButton.styleFrom(
                          backgroundColor: Palette.googleColor,
                          maximumSize: Size(200, 50),
                          minimumSize: Size(200, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)
                          ),
                        ),
                        icon: Icon(Icons.add, color: Colors.white, size: 25, ),
                        label: Text('Google',
                          style: TextStyle(color: Colors.white,
                              fontSize: 20
                          ),
                        ),
                      )
                    ],
                  )
              ),
              // 구글 로그인
            ],
          ),
        ),
      ),
    );
  }
}

