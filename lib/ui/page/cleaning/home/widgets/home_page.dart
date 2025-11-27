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
        title: Obx(() => controller.searchQuery.value.isEmpty
            ? Text(
                '청소5분대기조',
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
      body: Obx(() {
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
        constraints: BoxConstraints(minHeight: 160),
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
                        fontSize: 18,
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
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    if (request.address != null)
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[500]),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              request.address!,
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
                    Row(
                      children: [
                        if (request.price != null && request.price!.isNotEmpty) ...[
                          Icon(Icons.attach_money, size: 16, color: Color(0xFF1E88E5)),
                          Text(
                            '${request.price}원',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1E88E5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 12),
                        ],
                        Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            DateFormat('yyyy.MM.dd HH:mm').format(request.createdAt),
                            style: TextStyle(
                              fontSize: 13,
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
                constraints: BoxConstraints(
                  maxWidth: 160,
                  maxHeight: 160,
                  minWidth: 160,
                  minHeight: 160,
                ),
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
