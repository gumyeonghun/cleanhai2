import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanhai2/data/model/cleaning_recommendation.dart';
import '../cleaning_recommendation_controller.dart';

class CleaningRecommendationDetailPage extends StatelessWidget {
  final CleaningRecommendation recommendation;

  const CleaningRecommendationDetailPage({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CleaningRecommendationController>();
    
    // Check if current user is author
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAuthor = currentUser != null && currentUser.uid == recommendation.authorId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        actions: [
          if (isAuthor)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                Get.defaultDialog(
                  title: '삭제 확인',
                  middleText: '정말로 이 추천글을 삭제하시겠습니까?',
                  textConfirm: '삭제',
                  textCancel: '취소',
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                  onConfirm: () {
                    Get.back(); // Close dialog
                    controller.deleteRecommendation(recommendation.id);
                  },
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (recommendation.imageUrl != null && recommendation.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: recommendation.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 250,
                  color: Colors.grey[100],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 250,
                  color: Colors.grey[100],
                  child: Center(child: Icon(Icons.error)),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    recommendation.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Address (if exists)
                  if (recommendation.address != null && recommendation.address!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Color(0xFF1E88E5)),
                        SizedBox(width: 4),
                        Text(
                          recommendation.address!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1E88E5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 16),
                  
                  // Author Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[200],
                        child: Icon(Icons.person, color: Colors.grey[500]),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation.authorName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            DateFormat('yyyy.MM.dd HH:mm').format(recommendation.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(height: 32),
                  
                  // Content
                  Text(
                    recommendation.content,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
