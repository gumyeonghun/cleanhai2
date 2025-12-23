import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cleanhai2/data/model/cleaning_knowhow.dart';
import '../cleaning_knowhow_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CleaningKnowhowDetailPage extends StatelessWidget {
  final CleaningKnowhow knowhow;

  const CleaningKnowhowDetailPage({super.key, required this.knowhow});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CleaningKnowhowController>();
    
    // Check if current user is author
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAuthor = currentUser != null && currentUser.uid == knowhow.authorId;

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
                  middleText: '정말로 이 노하우를 삭제하시겠습니까?',
                  textConfirm: '삭제',
                  textCancel: '취소',
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                  onConfirm: () {
                    Get.back(); // Close dialog
                    controller.deleteKnowhow(knowhow.id);
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
            if (knowhow.imageUrl != null && knowhow.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: knowhow.imageUrl!,
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
                    knowhow.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
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
                            knowhow.authorName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            DateFormat('yyyy.MM.dd HH:mm').format(knowhow.createdAt),
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
                    knowhow.content,
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
