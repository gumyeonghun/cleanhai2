
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final _authentication = FirebaseAuth.instance;

  bool showSpinner = false;
  bool isSignupScreen = true;
  final _formKey = GlobalKey<FormState>();
  String userName = '';
  String userEmail = '';
  String userPassword = '';
  String userType = 'owner'; // 'owner' or 'staff'

  void _tryValidation() {
    final isValid = _formKey.currentState!.validate();
    if (isValid) {
      _formKey.currentState!.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              // Background Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6A11CB), // Deep Purple
                      Color(0xFF2575FC), // Blue
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              
              // Content
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo / Title
                      Text(
                        '청소5분대기조',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Korea No.1 Cleaning Service',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 40),

                      // Main Card
                      Container(
                        padding: EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Toggle Login/Signup
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTabButton(
                                      title: '로그인',
                                      isSelected: !isSignupScreen,
                                      onTap: () {
                                        setState(() {
                                          isSignupScreen = false;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildTabButton(
                                      title: '회원가입',
                                      isSelected: isSignupScreen,
                                      onTap: () {
                                        setState(() {
                                          isSignupScreen = true;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 30),

                              // Name Field (Signup only)
                              if (isSignupScreen) ...[
                                _buildTextField(
                                  key: ValueKey(1),
                                  hintText: '이름',
                                  icon: Icons.person_outline,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return '이름을 입력해 주세요';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => userName = value!,
                                  onChanged: (value) => userName = value,
                                ),
                                SizedBox(height: 16),
                              ],

                              // Email Field
                              _buildTextField(
                                key: ValueKey(isSignupScreen ? 2 : 4),
                                hintText: '이메일',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value!.isEmpty || !value.contains('@')) {
                                    return '올바른 이메일 형식을 입력해 주세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) => userEmail = value!,
                                onChanged: (value) => userEmail = value,
                              ),
                              SizedBox(height: 16),

                              // Password Field
                              _buildTextField(
                                key: ValueKey(isSignupScreen ? 3 : 5),
                                hintText: '비밀번호',
                                icon: Icons.lock_outline,
                                obscureText: true,
                                validator: (value) {
                                  if (value!.isEmpty || value.length < 6) {
                                    return '6자 이상 입력해 주세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) => userPassword = value!,
                                onChanged: (value) => userPassword = value,
                              ),
                              
                              // Role Selection (Signup only)
                              if (isSignupScreen) ...[
                                SizedBox(height: 24),
                                Text(
                                  '회원 유형',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildRoleButton(
                                        title: '숙박업소',
                                        value: 'owner',
                                        groupValue: userType,
                                        onTap: () {
                                          setState(() {
                                            userType = 'owner';
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: _buildRoleButton(
                                        title: '청소직원',
                                        value: 'staff',
                                        groupValue: userType,
                                        onTap: () {
                                          setState(() {
                                            userType = 'staff';
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              SizedBox(height: 30),

                              // Submit Button
                              ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF2575FC),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                  shadowColor: Color(0xFF2575FC).withValues(alpha: 0.4),
                                ),
                                child: Text(
                                  isSignupScreen ? '회원가입' : '로그인',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              SizedBox(height: 20),
                              
                              // Divider
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey[300])),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey[300])),
                                ],
                              ),
                              
                              SizedBox(height: 20),

                              // Google Login Button
                              OutlinedButton.icon(
                                onPressed: () {
                                  // Google Login Logic (Placeholder)
                                },
                                icon: Icon(Icons.add, size: 18), // Replace with Google Icon if available
                                label: Text('Google로 계속하기'),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  foregroundColor: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Color(0xFF2575FC) : Colors.grey[400],
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF2575FC) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required Key key,
    required String hintText,
    required IconData icon,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
    required ValueChanged<String> onChanged,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      key: key,
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2575FC), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[200]!),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required String title,
    required String value,
    required String groupValue,
    required VoidCallback onTap,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2575FC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF2575FC) : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF2575FC).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    setState(() {
      showSpinner = true;
    });

    _tryValidation();

    try {
      if (isSignupScreen) {
        // Signup Logic
        final newUser = await _authentication.createUserWithEmailAndPassword(
          email: userEmail,
          password: userPassword,
        );

        await FirebaseFirestore.instance.collection('users').doc(newUser.user!.uid).set({
          'userName': userName,
          'email': userEmail,
          'userType': userType,
        });

        if (newUser.user != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('회원가입 성공!')),
            );
          }
        }
      } else {
        // Login Logic
        final newUser = await _authentication.signInWithEmailAndPassword(
          email: userEmail,
          password: userPassword,
        );
        
        if (newUser.user != null) {
          // Navigation handled by stream listener in main.dart usually, 
          // or we can navigate manually if needed.
        }
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSignupScreen ? '회원가입 실패: 입력 정보를 확인해주세요.' : '로그인 실패: 이메일과 비밀번호를 확인해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          showSpinner = false;
        });
      }
    }
  }
}
