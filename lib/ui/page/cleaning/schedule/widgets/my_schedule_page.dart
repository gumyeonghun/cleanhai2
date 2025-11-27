import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import '../my_schedule_controller.dart';
import '../../detail/widgets/detail_page.dart';
import '../../progress/widgets/cleaning_progress_page.dart';

class MySchedulePage extends StatelessWidget {
  const MySchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyScheduleController());
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            '내 청소일정',
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
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: '내 의뢰'),
              Tab(text: '내 신청'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [
              // 내 의뢰 탭
              _buildMyRequestsTab(controller, myUid),
              // 내 신청 탭
              _buildMyApplicationsTab(controller, myUid),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMyRequestsTab(MyScheduleController controller, String myUid) {
    return Obx(() {
      final requests = controller.myAcceptedRequests;

      if (requests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text(
                '수락된 청소 의뢰가 없습니다',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView.separated(
          itemCount: requests.length,
          padding: EdgeInsets.only(bottom: 80, top: 20),
          itemBuilder: (context, index) => _requestCard(requests[index], myUid, true),
          separatorBuilder: (context, index) => SizedBox(height: 16),
        ),
      );
    });
  }

  Widget _buildMyApplicationsTab(MyScheduleController controller, String myUid) {
    return Obx(() {
      final requests = controller.myAppliedRequests;

      if (requests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work_outline, size: 60, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text(
                '신청한 청소 의뢰가 없습니다',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView.separated(
          itemCount: requests.length,
          padding: EdgeInsets.only(bottom: 80, top: 20),
          itemBuilder: (context, index) => _requestCard(requests[index], myUid, false),
          separatorBuilder: (context, index) => SizedBox(height: 16),
        ),
      );
    });
  }

  Widget _requestCard(CleaningRequest request, String myUid, bool isMyRequest) {
    final isAccepted = request.acceptedApplicantId != null;
    final isAcceptedByMe = request.acceptedApplicantId == myUid;

    return GestureDetector(
      onTap: () {
        Get.to(() => DetailPage(cleaningRequest: request));
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.all(16),
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
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 20, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.address ?? '주소 정보 없음',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _statusBadge(isMyRequest, isAccepted, isAcceptedByMe),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.attach_money, size: 20, color: Color(0xFFE53935)),
                SizedBox(width: 8),
                Text(
                  '${NumberFormat('#,###').format(int.tryParse(request.price ?? '0') ?? 0)}원',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53935),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                SizedBox(width: 8),
                Text(
                  DateFormat('yyyy.MM.dd HH:mm').format(request.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (isAccepted)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Get.to(() => CleaningProgressPage(
                      requestId: request.id,
                      isStaff: !isMyRequest, // 내 의뢰가 아니면(내 신청이면) 직원임
                    ));
                  },
                  icon: Icon(Icons.assignment_turned_in_outlined, size: 18),
                  label: Text('진행 상황 확인'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFFE53935),
                    side: BorderSide(color: Color(0xFFE53935)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(bool isMyRequest, bool isAccepted, bool isAcceptedByMe) {
    String text;
    Color bgColor;
    Color textColor;

    if (isMyRequest) {
      // 내 의뢰 탭: 항상 수락됨
      text = '수락됨';
      bgColor = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green[700]!;
    } else {
      // 내 신청 탭
      if (isAcceptedByMe) {
        text = '수락됨';
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green[700]!;
      } else if (isAccepted) {
        text = '마감됨';
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey[700]!;
      } else {
        text = '대기중';
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange[700]!;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
