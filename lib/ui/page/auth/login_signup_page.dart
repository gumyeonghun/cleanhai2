import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class LoginSignupPage extends StatelessWidget {
  const LoginSignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthController());

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E88E5), // Trustworthy Blue
              Color(0xFF64B5F6), // Light Blue
              Color(0xFFE3F2FD), // Very Light Blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      // Logo/Title
                      Text(
                        '청소 매칭 서비스',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '깨끗한 공간, 편리한 매칭',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      SizedBox(height: 50),

                      // Tab Buttons
                      Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTabButton(
                            title: '로그인',
                            isSelected: !controller.isSignupScreen.value,
                            onTap: () => controller.toggleScreen(false),
                          ),
                          SizedBox(width: 40),
                          _buildTabButton(
                            title: '회원가입',
                            isSelected: controller.isSignupScreen.value,
                            onTap: () => controller.toggleScreen(true),
                          ),
                        ],
                      )),
                      SizedBox(height: 30),

                      // Form Card
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Obx(() => Form(
                          key: controller.formKey,
                          child: Column(
                            children: [
                              // Signup Additional Fields
                              if (controller.isSignupScreen.value) ...[
                                // Name Field
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
                              SizedBox(height: 16),

                              // Signup Additional Fields
                              if (controller.isSignupScreen.value) ...[
                                // Confirm Password
                                _buildTextField(
                                  key: ValueKey('confirmPassword'),
                                  hintText: '비밀번호 확인',
                                  icon: Icons.lock_outline,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '비밀번호를 다시 입력해 주세요';
                                    }
                                    if (value != controller.userPassword) {
                                      return '비밀번호가 일치하지 않습니다';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => controller.confirmPassword = value!,
                                  onChanged: (value) => controller.confirmPassword = value,
                                ),
                                SizedBox(height: 16),

                                // Address
                                _buildTextField(
                                  key: ValueKey('address'),
                                  hintText: '주소',
                                  icon: Icons.home_outlined,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '주소를 입력해 주세요';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) => controller.userAddress = value!,
                                  onChanged: (value) => controller.userAddress = value,
                                ),
                                SizedBox(height: 16),

                                // Birth Date
                                _buildDatePicker(context, controller),
                                SizedBox(height: 16),
                              ],

                              
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
                                        title: '청소 의뢰인',
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

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: Obx(() => ElevatedButton(
                                  onPressed: controller.isLoading.value ? null : controller.submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF1E88E5), // Trustworthy Blue
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: controller.isLoading.value
                                      ? SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          controller.isSignupScreen.value ? '회원가입' : '로그인',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                )),
                              ),

                              // Social Login Buttons (Login only)
                              if (!controller.isSignupScreen.value) ...[
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
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
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
                                ),
                                
                                SizedBox(height: 12),
                                
                                // Apple Login Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
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
                                ),
                              ],
                            ],
                          ),
                        )),
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
              color: isSelected ? Color(0xFF1E88E5) : Colors.grey[400],
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF1E88E5) : Colors.transparent,
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
          borderSide: BorderSide(color: Color(0xFF1E88E5), width: 1.5),
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
          color: isSelected ? Color(0xFF1E88E5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF1E88E5) : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF1E88E5).withValues(alpha: 0.3),
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

  Widget _buildDatePicker(BuildContext context, AuthController controller) {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(Duration(days: 365 * 20)), // Default to 20 years ago
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          locale: const Locale('ko', 'KR'),
        );
        if (picked != null) {
          controller.setBirthDate(picked);
        }
      },
      child: AbsorbPointer(
        child: Obx(() => TextFormField(
          key: ValueKey('birthDate'),
          decoration: InputDecoration(
            hintText: '생년월일',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey[400], size: 20),
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
          ),
          controller: TextEditingController(
            text: controller.userBirthDate.value != null 
                ? "${controller.userBirthDate.value!.year}-${controller.userBirthDate.value!.month.toString().padLeft(2, '0')}-${controller.userBirthDate.value!.day.toString().padLeft(2, '0')}"
                : ""
          ),
          validator: (value) {
            if (controller.userBirthDate.value == null) {
              return '생년월일을 선택해 주세요';
            }
            return null;
          },
        )),
      ),
    );
  }
}
