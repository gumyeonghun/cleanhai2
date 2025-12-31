import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cleanhai2/data/model/cleaning_recommendation.dart';
import '../cleaning_recommendation_controller.dart';
import 'cleaning_recommendation_write_page.dart';
import 'cleaning_recommendation_detail_page.dart';

class CleaningRecommendationPage extends StatelessWidget {
  const CleaningRecommendationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CleaningRecommendationController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '내가 추천하는 우리동네청소',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
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
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.recommendations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.thumb_up_outlined, size: 60, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  '등록된 추천글이 없습니다.\n우리 동네 청소 꿀팁을 공유해보세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: controller.recommendations.length,
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            final recommendation = controller.recommendations[index];
            return _recommendationItem(context, recommendation);
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.clearWriteForm();
          Get.to(() => CleaningRecommendationWritePage());
        },
        backgroundColor: Color(0xFF1E88E5),
        icon: Icon(Icons.edit, color: Colors.white),
        label: Text('추천하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _recommendationItem(BuildContext context, CleaningRecommendation recommendation) {
    return GestureDetector(
      onTap: () {
        Get.to(() => CleaningRecommendationDetailPage(recommendation: recommendation));
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (if exists)
            if (recommendation.imageUrl != null && recommendation.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: recommendation.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: Colors.grey[100],
                    child: Center(child: Icon(Icons.image, color: Colors.grey[300])),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: Colors.grey[100],
                    child: Center(child: Icon(Icons.error, color: Colors.grey[300])),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  if (recommendation.address != null && recommendation.address!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Color(0xFF1E88E5)),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            recommendation.address!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1E88E5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 8),
                  Text(
                    recommendation.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey[400]),
                      SizedBox(width: 4),
                      Text(
                        recommendation.authorName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      Spacer(),
                      Text(
                        DateFormat('yyyy.MM.dd').format(recommendation.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
