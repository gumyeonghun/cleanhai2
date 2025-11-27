import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import '../staff_waiting_controller.dart';
import '../../write/widgets/write_page.dart';

class StaffWaitingPage extends StatelessWidget {
  const StaffWaitingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StaffWaitingController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '대기중인 청소 전문가',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      floatingActionButton: Obx(() {
        final user = controller.currentUser.value;
        final isStaff = user?.userType == 'staff';
        
        if (!isStaff) {
          // 청소 직원이 아니면 FAB 숨김
          return SizedBox.shrink();
        }
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 프로필로 등록 버튼
            if (controller.isFabExpanded.value) ...[
              FloatingActionButton.extended(
                onPressed: () {
                  controller.registerWithProfile();
                  controller.toggleFab();
                },
                heroTag: 'profile',
                backgroundColor: Colors.green,
                icon: Icon(Icons.person_add),
                label: Text('프로필로 등록'),
              ),
              SizedBox(height: 12),
            ],
            // 직접 작성 버튼
            if (controller.isFabExpanded.value) ...[
              FloatingActionButton.extended(
                onPressed: () {
                  Get.to(() => WritePage(type: 'staff'));
                  controller.toggleFab();
                },
                heroTag: 'write',
                backgroundColor: Color(0xFFE53935),
                icon: Icon(Icons.edit),
                label: Text('직접 작성'),
              ),
              SizedBox(height: 12),
            ],
            // 메인 FAB
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFE53935).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: controller.toggleFab,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: AnimatedRotation(
                  turns: controller.isFabExpanded.value ? 0.125 : 0,
                  duration: Duration(milliseconds: 200),
                  child: Icon(Icons.add),
                ),
              ),
            ),
          ],
        );
      }),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        final staff = controller.sortedStaff;

        if (staff.isEmpty) {
           return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  '대기 중인 청소 전문가가 없습니다',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView.separated(
            itemCount: staff.length,
            padding: EdgeInsets.only(bottom: 80, top: 20),
            itemBuilder: (context, index) => _staffItem(context, staff[index]),
            separatorBuilder: (context, index) => SizedBox(height: 16),
          ),
        );
      }),
    );
  }

  Widget _staffItem(BuildContext context, CleaningStaff staff) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Staff Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFFE53935)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 30,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16),
          
          // Staff Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.authorName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                if (staff.title.isNotEmpty)
                  Text(
                    staff.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 4),
                if (staff.address != null)
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          staff.address!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 4),
                Text(
                  DateFormat('yyyy.MM.dd HH:mm').format(staff.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          
          // Action Button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFFE53935).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '대기중',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
