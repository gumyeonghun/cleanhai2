import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import 'package:cleanhai2/ui/page/cleaning/detail/widgets/detail_page.dart';
import '../cleaning_ranking_controller.dart';

class CleaningRankingPage extends StatelessWidget {
  const CleaningRankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CleaningRankingController());
    final tabs = [
      '전체',
      '숙박업소청소',
      '사무실청소',
      '건물청소',
      '가게청소',
      '출장손세차',
      '특수청소',
      '입주청소',
      '가정집청소',
      '기타'
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            '청소 전문가 랭킹',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: tabs.map((tab) => Tab(text: tab)).toList(),
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: tabs.map((category) {
              final staffList = controller.getStaffByCategory(category);

              if (staffList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 60, color: Colors.grey[300]),
                      SizedBox(height: 16),
                      Text(
                        '랭킹 정보가 없습니다',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: staffList.length,
                padding: EdgeInsets.all(16),
                itemBuilder: (context, index) => _rankingItem(context, staffList[index], index + 1, controller),
                separatorBuilder: (context, index) => SizedBox(height: 16),
              );
            }).toList(),
          );
        }),
      ),
    );
  }

  Widget _rankingItem(BuildContext context, CleaningStaff staff, int rank, CleaningRankingController controller) {
    Color rankColor;
    if (rank == 1) {
      rankColor = Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      rankColor = Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      rankColor = Color(0xFFCD7F32); // Bronze
    } else {
      rankColor = Colors.grey[400]!;
    }

    return GestureDetector(
      onTap: () {
        Get.to(() => DetailPage(cleaningStaff: staff));
      },
      child: Container(
        constraints: BoxConstraints(minHeight: 100),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank Number
            Container(
              width: 50,
              height: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank <= 3 ? rankColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            
            // Staff Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          staff.authorName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(width: 8),
                        if (staff.cleaningType != null && staff.cleaningType!.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(0xFF1E88E5).withOpacity(0.1),
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
                    SizedBox(height: 4),
                    Text(
                      staff.title.isNotEmpty ? staff.title : '자기소개가 없습니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    // Ratings
                    Obx(() {
                      final avgRating = controller.staffAverageRatings[staff.authorId] ?? 0.0;
                      final reviewCount = controller.staffReviewCounts[staff.authorId] ?? 0;
                      
                      return Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '($reviewCount)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Staff Image (Small Circle)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
                child: ClipOval(
                  child: (staff.imageUrl != null && staff.imageUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: staff.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(Icons.person, color: Colors.grey[400]),
                          errorWidget: (context, url, error) => Icon(Icons.person, color: Colors.grey[400]),
                        )
                      : Icon(Icons.person, size: 30, color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
