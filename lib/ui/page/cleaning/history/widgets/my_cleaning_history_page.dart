import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/ui/page/cleaning/detail/widgets/detail_page.dart';
import '../my_cleaning_history_controller.dart';

class MyCleaningHistoryPage extends StatelessWidget {
  const MyCleaningHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyCleaningHistoryController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '내 청소 관리',
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

        final requests = controller.completedRequests;

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt, size: 60, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  '청소 내역이 없습니다',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: requests.length,
          padding: EdgeInsets.all(16),
          itemBuilder: (context, index) => _historyItem(context, requests[index]),
          separatorBuilder: (context, index) => SizedBox(height: 16),
        );
      }),
    );
  }

  Widget _historyItem(BuildContext context, CleaningRequest request) {
    final controller = Get.find<MyCleaningHistoryController>();
    
    // Status Logic
    String statusText;
    Color statusColor;
    Color statusBgColor;

    if (request.status == 'completed') {
      statusText = '완료됨';
      statusColor = Colors.green;
      statusBgColor = Colors.green.withOpacity(0.1);
    } else if (request.status == 'in_progress') {
      statusText = '진행중';
      statusColor = Colors.blue;
      statusBgColor = Colors.blue.withOpacity(0.1);
    } else if (request.status == 'accepted') {
      // Accepted but check payment
      if (request.acceptedApplicantId != null && request.paymentStatus != 'completed') {
        if (request.authorId == controller.currentUser.value?.id) {
            statusText = '결제 대기';
            statusColor = Colors.orange;
            statusBgColor = Colors.orange.withOpacity(0.1);
        } else {
             statusText = '수락됨 (결제대기)';
             statusColor = Colors.orange;
             statusBgColor = Colors.orange.withOpacity(0.1);
        }
      } else {
        statusText = '매칭 완료';
        statusColor = Color(0xFF1E88E5);
        statusBgColor = Color(0xFF1E88E5).withOpacity(0.1);
      }
    } else {
      // Pending
      if (request.targetStaffId != null) {
         statusText = '지명대기중'; 
         statusColor = Colors.purple;
         statusBgColor = Colors.purple.withOpacity(0.1);
      } else {
        statusText = '대기중';
        statusColor = Colors.grey;
        statusBgColor = Colors.grey.withOpacity(0.1);
      }
    }

    final isPaymentPending = request.status == 'accepted' && 
                             request.paymentStatus != 'completed' &&
                             controller.currentUser.value?.id == request.authorId;

    return GestureDetector(
      onTap: () {
        Get.to(() => DetailPage(cleaningRequest: request));
      },
      child: Container(
        constraints: BoxConstraints(minHeight: 140),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(
                          DateFormat('yyyy.MM.dd').format(request.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
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
                    SizedBox(height: 6),
                    Text(
                      request.content,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (request.price != null && request.price!.isNotEmpty)
                          Text(
                            '${request.price}원',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E88E5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (isPaymentPending)
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () {
                                controller.payForRequest(request);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1E88E5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: Text(
                                '결제하기',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                width: 100,
                height: 140, // Height might vary, but 140 is minHeight
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
