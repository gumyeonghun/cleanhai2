import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import '../staff_waiting_controller.dart';
import '../../write/widgets/write_page.dart';
import '../../detail/widgets/detail_page.dart';
import 'staff_profile_write_page.dart';

class StaffWaitingPage extends StatelessWidget {
  const StaffWaitingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StaffWaitingController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Obx(() => controller.searchQuery.value.isEmpty
            ? Text(
                '대기중인 청소 전문가',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              )
            : TextField(
                autofocus: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '이름, 제목, 내용, 주소로 검색...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) => controller.updateSearchQuery(value),
              )),
        centerTitle: true,
        elevation: 0,
        actions: [
          Obx(() => IconButton(
                icon: Icon(
                  controller.searchQuery.value.isEmpty ? Icons.search : Icons.close,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (controller.searchQuery.value.isEmpty) {
                    controller.updateSearchQuery(' '); // 검색 모드 활성화
                  } else {
                    controller.updateSearchQuery(''); // 검색 모드 비활성화
                  }
                },
              )),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
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
            // 확장된 버튼들
            if (controller.isFabExpanded.value) ...[
              // 직접 작성하기 버튼
              FloatingActionButton.extended(
                onPressed: () {
                  Get.to(() => StaffProfileWritePage());
                  controller.toggleFab();
                },
                heroTag: 'write',
                backgroundColor: Color(0xFF1E88E5),
                icon: Icon(Icons.edit),
                label: Text('직접 작성하기'),
              ),
              SizedBox(height: 12),
              // 프로필로 빠른 등록 버튼
              FloatingActionButton.extended(
                onPressed: () {
                  controller.registerWithProfile();
                  controller.toggleFab();
                },
                heroTag: 'profile',
                backgroundColor: Colors.green,
                icon: Icon(Icons.person_add),
                label: Text('프로필로 빠른 등록'),
              ),
              SizedBox(height: 12),
            ],
            // 메인 FAB 버튼
            FloatingActionButton(
              onPressed: controller.toggleFab,
              backgroundColor: Color(0xFF1E88E5),
              child: Icon(
                controller.isFabExpanded.value ? Icons.close : Icons.add,
                color: Colors.white,
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
    final controller = Get.find<StaffWaitingController>();
    
    return InkWell(
      onTap: () {
        // 청소 전문가 상세 페이지로 이동
        Get.to(() => DetailPage(cleaningStaff: staff));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 35,
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  if (staff.title.isNotEmpty)
                    Text(
                      staff.title,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 4),
                  // 평점 표시
                  Obx(() {
                    final ratings = controller.staffRatings[staff.authorId];
                    if (ratings != null && ratings['reviewCount'] > 0) {
                      final avgRating = ratings['averageRating'] as double;
                      final reviewCount = ratings['reviewCount'] as int;
                      return Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            '${avgRating.toStringAsFixed(1)} ($reviewCount)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Text(
                        '아직 후기가 없습니다',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      );
                    }
                  }),
                  SizedBox(height: 4),
                  if (staff.address != null)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[500]),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            staff.address!,
                            style: TextStyle(
                              fontSize: 13,
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
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Button
            Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E88E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '대기중',
                    style: TextStyle(
                      color: Color(0xFF1E88E5),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // Request Button (Only for non-staff users)
                Obx(() {
                  final user = controller.currentUser.value;
                  if (user != null && user.userType == 'owner') {
                    return ElevatedButton(
                      onPressed: () {
                        Get.to(() => WritePage(
                          type: 'request',
                          targetStaffId: staff.authorId,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '의뢰하기',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
