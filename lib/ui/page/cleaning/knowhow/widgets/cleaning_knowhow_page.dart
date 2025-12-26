import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cleanhai2/data/model/cleaning_knowhow.dart';
import '../cleaning_knowhow_controller.dart';
import 'cleaning_knowhow_write_page.dart';
import 'cleaning_knowhow_detail_page.dart';

class CleaningKnowhowPage extends StatelessWidget {
  const CleaningKnowhowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CleaningKnowhowController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '청소 노하우',
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
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.knowhows.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb_outline, size: 60, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  '등록된 노하우가 없습니다.\n첫 번째 노하우를 공유해보세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: controller.knowhows.length,
          separatorBuilder: (context, index) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            final knowhow = controller.knowhows[index];
            return _knowhowItem(context, knowhow);
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.clearWriteForm();
          Get.to(() => CleaningKnowhowWritePage());
        },
        backgroundColor: Color(0xFF1E88E5),
        icon: Icon(Icons.edit, color: Colors.white),
        label: Text('노하우 공유', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _knowhowItem(BuildContext context, CleaningKnowhow knowhow) {
    return GestureDetector(
      onTap: () {
        Get.to(() => CleaningKnowhowDetailPage(knowhow: knowhow));
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (if exists)
            if (knowhow.imageUrl != null && knowhow.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: knowhow.imageUrl!,
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
                    knowhow.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    knowhow.content,
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
                        knowhow.authorName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      Spacer(),
                      Text(
                        DateFormat('yyyy.MM.dd').format(knowhow.createdAt),
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
