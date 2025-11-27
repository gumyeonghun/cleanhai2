import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'auth_controller.dart';

class LoginSignupPage extends StatelessWidget {
  const LoginSignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthController());
    // formKey removed from here

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE53935),
                  Colors.black,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Content
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent, // Ensure taps on empty space are caught
            child: Center(
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
                        key: controller.formKey, // Use persistent key from controller
                        child: Obx(() => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Toggle Login/Signup
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTabButton(
                                    title: '로그인',
                                    isSelected: !controller.isSignupScreen.value,
                                    onTap: controller.toggleScreenType,
                                  ),
                                ),
                                Expanded(
                                  child: _buildTabButton(
                                    title: '회원가입',
                                    isSelected: controller.isSignupScreen.value,
                                    onTap: controller.toggleScreenType,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30),

                            // Name Field (Signup only)
                            if (controller.isSignupScreen.value) ...[
                              _buildTextField(
                                key: ValueKey('name'),
                                hintText: '이름',
                                icon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '이름을 입력해 주세요';
                                  }
                                  return null;
                                },
                                onSaved: (value) => controller.userName = value!,
                                onChanged: (value) => controller.userName = value,
                              ),
                              SizedBox(height: 16),
                            ],

                            // Email Field
                            _buildTextField(
                              key: ValueKey('email'),
                              hintText: '이메일',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty || !value.contains('@')) {
                                  return '올바른 이메일 형식을 입력해 주세요';
                                }
                                return null;
                              },
                              onSaved: (value) => controller.userEmail = value!,
                              onChanged: (value) => controller.userEmail = value,
                            ),
                            SizedBox(height: 16),

                            // Password Field
                            _buildTextField(
                              key: ValueKey('password'),
                              hintText: '비밀번호',
                              icon: Icons.lock_outline,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty || value.length < 6) {
                                  return '6자 이상 입력해 주세요';
                                }
                                return null;
                              },
                              onSaved: (value) => controller.userPassword = value!,
                              onChanged: (value) => controller.userPassword = value,
                            ),
                            
                            // Role Selection (Signup only)
                            if (controller.isSignupScreen.value) ...[
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
                              Obx(() => Row(
                                children: [
                                  Expanded(
                                    child: _buildRoleButton(
                                      title: '청소 의뢰자',
                                      value: 'owner',
                                      groupValue: controller.userType.value,
                                      onTap: () => controller.setUserType('owner'),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: _buildRoleButton(
                                      title: '청소 전문가',
                                      value: 'staff',
                                      groupValue: controller.userType.value,
                                      onTap: () => controller.setUserType('staff'),
                                    ),
                                  ),
                                ],
                              )),
                            ],

                            SizedBox(height: 30),

                            // Submit Button
                            ElevatedButton(
                              onPressed: () => controller.submitForm(), // No argument needed
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFE53935),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                                shadowColor: Color(0xFFE53935).withValues(alpha: 0.4),
                              ),
                              child: Text(
                                controller.isSignupScreen.value ? '회원가입' : '로그인',
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
                                controller.signInWithGoogle();
                              },
                              icon: Icon(Icons.add, size: 18),
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
                            
                            SizedBox(height: 12),
                            
                            // Apple Login Button
                            OutlinedButton.icon(
                              onPressed: () {
                                controller.signInWithApple();
                              },
                              icon: Icon(Icons.apple, size: 20),
                              label: Text('Apple로 계속하기'),
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
                        )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading Spinner Overlay
          Obx(() => controller.showSpinner.value
            ? Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : SizedBox.shrink()
          ),
        ],
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
              color: isSelected ? Color(0xFFE53935) : Colors.grey[400],
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFFE53935) : Colors.transparent,
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
          borderSide: BorderSide(color: Colors.black, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE53935), width: 1.5),
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
          color: isSelected ? Color(0xFFE53935) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFFE53935) : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFFE53935).withValues(alpha: 0.3),
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
}
