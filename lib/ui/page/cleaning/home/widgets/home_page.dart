import 'package:cleanhai2/ui/page/cleaning/write/widgets/write_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import '../home_controller.dart';
import '../../detail/widgets/detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CleaningController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '청소5분대기조',
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
      floatingActionButton: Container(
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
          onPressed: () {
            Get.to(() => WritePage());
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.edit),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        final requests = controller.cleaningRequests;

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
          padding: EdgeInsets.only(top: 20, bottom: 80),
          itemBuilder: (context, index) => _requestItem(context, requests[index]),
          separatorBuilder: (context, index) => SizedBox(height: 16),
        );
      }),
    );
  }

  Widget _requestItem(BuildContext context, CleaningRequest request) {
    return GestureDetector(
      onTap: () {
        Get.to(() => DetailPage(cleaningRequest: request));
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        height: 130,
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
                  children: [
                    Text(
                      request.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        request.content,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      DateFormat('yyyy.MM.dd HH:mm').format(request.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (request.imageUrl != null && request.imageUrl!.isNotEmpty)
              Container(
                width: 130,
                height: 130,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    request.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[100],
                        child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
