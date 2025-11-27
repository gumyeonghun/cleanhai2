import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../main_controller.dart';
import '../../cleaning/home/widgets/home_page.dart';
import '../../cleaning/staff_waiting/widgets/staff_waiting_page.dart';
import '../../cleaning/schedule/widgets/my_schedule_page.dart';
import '../../cleaning/profile/widgets/profile_page.dart';
import '../../chat/chat_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainController());

    return Scaffold(
      body: Obx(() {
        switch (controller.currentIndex.value) {
          case 0:
            return HomePage();
          case 1:
            return StaffWaitingPage();
          case 2:
            return MySchedulePage();
          case 3:
            return ChatPage();
          case 4:
            return ProfilePage();
          default:
            return HomePage();
        }
      }),
      bottomNavigationBar: Obx(() => Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF1E88E5),
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          iconSize: 26,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          currentIndex: controller.currentIndex.value,
          elevation: 0,
          onTap: controller.changeIndex,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '청소의뢰',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: '청소대기',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: '내청소일정',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: '채팅',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '프로필',
            ),
          ],
        ),
      )),
    );
  }
}
