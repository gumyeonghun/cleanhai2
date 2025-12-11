import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import '../staff_waiting_controller.dart';
import '../../detail/widgets/detail_page.dart';
import 'staff_profile_write_page.dart';

import 'package:cleanhai2/ui/page/cleaning/ranking/widgets/cleaning_ranking_page.dart';
import 'package:cleanhai2/ui/page/cleaning/history/widgets/my_cleaning_history_page.dart';
import 'package:cleanhai2/ui/page/cleaning/knowhow/widgets/cleaning_knowhow_page.dart';
import 'package:cleanhai2/ui/page/cleaning/recommendation/widgets/cleaning_recommendation_page.dart';

class StaffWaitingPage extends StatelessWidget {
  const StaffWaitingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StaffWaitingController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: PopupMenuButton<String>(
          icon: Icon(Icons.menu, color: Colors.white),
          onSelected: (String value) {
            if (value == '청소랭킹') {
              Get.to(() => CleaningRankingPage());
            } else if (value == '내청소내역') {
              Get.to(() => MyCleaningHistoryPage());
            } else if (value == '청소노하우') {
              Get.to(() => CleaningKnowhowPage());
            } else if (value == '내가 추천하는 우리동네청소') {
              Get.to(() => CleaningRecommendationPage());
            }
          },
          itemBuilder: (BuildContext context) {
            return ['청소랭킹', '내청소내역', '청소노하우', '내가 추천하는 우리동네청소'].map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        ),
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
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 청소 종류 필터 (세로 사이드바)
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              itemCount: StaffWaitingController.cleaningTypeFilters.length,
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final type = StaffWaitingController.cleaningTypeFilters[index];
                return Obx(() {
                  final isSelected = controller.selectedCleaningTypeFilter.value == type;
                  return GestureDetector(
                    onTap: () {
                      controller.selectedCleaningTypeFilter.value = type;
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(0xFF1E88E5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            type,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              },
            ),
          ),
          
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }
              
              final staffList = controller.sortedStaff;

              if (staffList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off_outlined, size: 60, color: Colors.grey[300]),
                      SizedBox(height: 16),
                      Text(
                        '대기중인 청소 전문가가 없습니다',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: staffList.length,
                padding: EdgeInsets.only(top: 20, bottom: 80, left: 16, right: 16),
                itemBuilder: (context, index) => _staffItem(context, staffList[index]),
                separatorBuilder: (context, index) => SizedBox(height: 16),
              );
            }),
          ),
        ],
      ),
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
        constraints: BoxConstraints(minHeight: 140), // Match HomePage minHeight
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      staff.authorName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6),
                    // Title (if present)
                    if (staff.title.isNotEmpty) ...[
                       Text(
                        staff.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                    ],
                    // Content (Introduction)
                    Text(
                      staff.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    // Address
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
                    // Ratings & Cleaning Type
                    Row(
                      children: [
                        // Ratings
                        Obx(() {
                          final ratings = controller.staffRatings[staff.authorId];
                          if (ratings != null && ratings['reviewCount'] != null && ratings['reviewCount'] > 0) {
                            final avgRating = (ratings['averageRating'] as num).toDouble();
                            final reviewCount = ratings['reviewCount'] as int;
                            return Row(
                              children: [
                                Icon(Icons.star, size: 14, color: Colors.amber),
                                SizedBox(width: 4),
                                Text(
                                  avgRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '($reviewCount)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                SizedBox(width: 8),
                              ],
                            );
                          }
                          return SizedBox.shrink();
                        }),
                        // Cleaning Type
                        if (staff.cleaningType != null && staff.cleaningType!.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(0xFF1E88E5).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              staff.cleaningType!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1E88E5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Pricing Information
                    if (staff.cleaningPrice != null && staff.cleaningPrice!.isNotEmpty) ...[
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.payments_outlined, size: 14, color: Color(0xFF1E88E5)),
                          SizedBox(width: 4),
                          Text(
                            staff.cleaningPrice!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E88E5),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (staff.additionalOptionCost != null && staff.additionalOptionCost!.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.add_circle_outline, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              staff.additionalOptionCost!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (staff.imageUrl != null && staff.imageUrl!.isNotEmpty)
              Container(
                width: 100, // Match HomePage width
                height: 140, // Match HomePage height
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: staff.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[100],
                      child: Center(child: Icon(Icons.person, color: Colors.grey[300])),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[100],
                      child: Icon(Icons.person, color: Colors.grey[400]),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(Icons.person, size: 40, color: Colors.grey[300]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
