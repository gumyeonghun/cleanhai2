import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
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
      length: 3,
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
              colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
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
              Tab(text: '내 대기'),
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
              // 내 대기 탭
              _buildMyWaitingTab(controller, myUid),
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
                '등록된 청소 의뢰가 없습니다',
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

  Widget _buildMyWaitingTab(MyScheduleController controller, String myUid) {
    return Obx(() {
      final waitingProfile = controller.myWaitingProfile.value;

      if (waitingProfile == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search, size: 60, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text(
                '등록된 대기 프로필이 없습니다',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            _waitingProfileCard(waitingProfile),
          ],
        ),
      );
    });
  }

  Widget _waitingProfileCard(CleaningStaff profile) {
    return Container(
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.authorName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '대기중',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 16),
          if (profile.cleaningType != null) ...[
            Row(
              children: [
                Icon(Icons.cleaning_services, size: 20, color: Color(0xFF1E88E5)),
                SizedBox(width: 8),
                Text(
                  '청소 종류',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              profile.cleaningType!,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            SizedBox(height: 16),
          ],
          Row(
            children: [
              Icon(Icons.title, size: 20, color: Color(0xFF1E88E5)),
              SizedBox(width: 8),
              Text(
                '제목',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            profile.title,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.description, size: 20, color: Color(0xFF1E88E5)),
              SizedBox(width: 8),
              Text(
                '내용',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            profile.content,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          if (profile.address != null) ...[
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF1E88E5)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    profile.address!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
          if (profile.availableDays != null && profile.availableDays!.isNotEmpty) ...[
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Color(0xFF1E88E5)),
                SizedBox(width: 8),
                Text(
                  '가능한 요일',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: profile.availableDays!.map((day) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E88E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      color: Color(0xFF1E88E5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, size: 20, color: Colors.grey[500]),
              SizedBox(width: 8),
              Text(
                '등록일: ${DateFormat('yyyy.MM.dd HH:mm').format(profile.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
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
                Icon(Icons.attach_money, size: 20, color: Color(0xFF1E88E5)),
                SizedBox(width: 8),
                Text(
                  '${NumberFormat('#,###').format(int.tryParse(request.price ?? '0') ?? 0)}원',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
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
                    foregroundColor: Color(0xFF1E88E5),
                    side: BorderSide(color: Color(0xFF1E88E5)),
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
      if (isAccepted) {
        text = '수락됨';
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green[700]!;
      } else {
        text = '대기중';
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange[700]!;
      }
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
