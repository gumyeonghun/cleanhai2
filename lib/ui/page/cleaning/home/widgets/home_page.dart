import 'package:cleanhai2/ui/page/cleaning/write/widgets/write_page.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import '../home_controller.dart';
import '../../detail/widgets/detail_page.dart';

import 'package:cleanhai2/ui/page/cleaning/history/widgets/my_cleaning_history_page.dart';
import 'package:cleanhai2/ui/page/cleaning/ranking/widgets/cleaning_ranking_page.dart';
import 'package:cleanhai2/ui/page/cleaning/knowhow/widgets/cleaning_knowhow_page.dart';
import 'package:cleanhai2/ui/page/cleaning/recommendation/widgets/cleaning_recommendation_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CleaningController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: PopupMenuButton<String>(
          icon: Icon(Icons.menu, color: Colors.white),
          onSelected: (String value) {
            if (value == '내청소내역') {
              Get.to(() => MyCleaningHistoryPage());
            } else if (value == '청소랭킹') {
              Get.to(() => CleaningRankingPage());
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
                '청소 의뢰하기',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              )
            : TextField(
                autofocus: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '제목, 내용, 작성자, 주소로 검색...',
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF1E88E5).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Get.to(() => WritePage(type: 'request'));
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.edit),
        ),
      ),
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
              itemCount: CleaningController.cleaningTypeFilters.length,
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final type = CleaningController.cleaningTypeFilters[index];
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
                          // 아이콘 추가 (선택 사항, 필요시 아이콘 매핑 추가 가능)
                          // Icon(Icons.cleaning_services, color: isSelected ? Colors.white : Colors.grey[600], size: 20),
                          // SizedBox(height: 4),
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

          // 청소 의뢰 목록
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }
              
              final requests = controller.sortedRequests;

              if (requests.isEmpty) {
                 return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cleaning_services_outlined, size: 60, color: Colors.grey[300]),
                      SizedBox(height: 16),
                      Text(
                        '등록된 청소 의뢰가 없습니다',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: requests.length,
                padding: EdgeInsets.only(top: 20, bottom: 80, left: 16, right: 16),
                itemBuilder: (context, index) => _requestItem(context, requests[index]),
                separatorBuilder: (context, index) => SizedBox(height: 16),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _requestItem(BuildContext context, CleaningRequest request) {
    return GestureDetector(
      onTap: () {
        Get.to(() => DetailPage(cleaningRequest: request));
      },
      child: Container(
        // margin: EdgeInsets.symmetric(horizontal: 20), // Removed margin to save space
        constraints: BoxConstraints(minHeight: 140), // Reduced min height
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
                      request.title,
                      style: TextStyle(
                        fontSize: 16, // Reduced font size
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Text(
                      request.content,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 13, // Reduced font size
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    if (request.address != null)
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              request.address!,
                              style: TextStyle(
                                fontSize: 12, // Reduced font size
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        if (request.price != null && request.price!.isNotEmpty) ...[
                          Flexible( // Added Flexible
                            child: Text(
                              '${request.price}원',
                              style: TextStyle(
                                fontSize: 14, // Reduced font size
                                color: Color(0xFF1E88E5),
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                        Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            DateFormat('yyyy.MM.dd').format(request.createdAt), // Shortened date format
                            style: TextStyle(
                              fontSize: 12, // Reduced font size
                              color: Colors.grey[400],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (request.imageUrl != null && request.imageUrl!.isNotEmpty)
              Container(
                width: 100, // Reduced width
                height: 140, // Reduced height
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: request.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[100],
                      child: Center(child: Icon(Icons.image, color: Colors.grey[300])),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[100],
                      child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
