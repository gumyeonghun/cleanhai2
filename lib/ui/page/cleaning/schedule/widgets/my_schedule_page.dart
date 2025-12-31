import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import 'package:cleanhai2/data/model/user_model.dart';
import '../my_schedule_controller.dart';
import '../../detail/widgets/detail_page.dart';
import '../../progress/widgets/cleaning_progress_page.dart';
import '../../report/widgets/completion_report_view_page.dart';

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
              Tab(text: '내 청소의뢰'),
              Tab(text: '내 청소신청'),
              Tab(text: '내 청소대기'),
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
          itemBuilder: (context, index) => _requestCard(requests[index], myUid, true, controller),
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
          itemBuilder: (context, index) => _requestCard(requests[index], myUid, false, controller),
          separatorBuilder: (context, index) => SizedBox(height: 16),
        ),
      );
    });
  }

  Widget _buildMyWaitingTab(MyScheduleController controller, String myUid) {
    return Obx(() {
      final waitingProfiles = controller.myWaitingProfiles;
      final targetedRequests = controller.myTargetedRequests;

      if (waitingProfiles.isEmpty && targetedRequests.isEmpty) {
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
            // 직접 받은 의뢰 표시
            if (targetedRequests.isNotEmpty) ...[
              Text(
                '받은 청소 의뢰',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              ...targetedRequests.map((request) => Column(
                children: [
                  _requestCard(request, myUid, false, controller),
                  SizedBox(height: 16),
                ],
              )),
              Divider(height: 32, thickness: 1),
            ],

            if (waitingProfiles.isNotEmpty) ...[
              Text(
                '내 대기 프로필 (${waitingProfiles.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              ...waitingProfiles.map((profile) => Column(
                children: [
                  _waitingProfileCard(profile),
                  SizedBox(height: 16),
                ],
              )),
            ],
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


  Widget _requestCard(CleaningRequest request, String myUid, bool isMyRequest, MyScheduleController controller) {
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
            // 예상 완료 시간 표시 (청소 진행중일 때)
            if (request.status == 'in_progress' && request.estimatedCompletionTime != null) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.orange[700]),
                    SizedBox(width: 8),
                    Text(
                      '예상 완료: ${DateFormat('HH:mm').format(request.estimatedCompletionTime!)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16),
            if (isMyRequest && isAccepted && request.paymentStatus != 'completed')
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.processPayment(request);
                    },
                    icon: Icon(Icons.payment, size: 18, color: Colors.white),
                    label: Text('청소비 결제하기', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1E88E5),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            if (isAccepted)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (request.status == 'completed' && request.completionReport != null) {
                       Get.to(() => CompletionReportViewPage(
                        report: request.completionReport!,
                        requestId: request.id,
                        canReview: isMyRequest && request.review == null,
                        review: request.review,
                      ));
                    } else {
                      Get.to(() => CleaningProgressPage(
                        requestId: request.id,
                        isStaff: !isMyRequest, // 내 의뢰가 아니면(내 신청이면) 직원임
                      ));
                    }
                  },
                  icon: Icon(
                    request.status == 'completed' 
                        ? Icons.assignment_turned_in 
                        : (request.status == 'in_progress' ? Icons.cleaning_services_outlined : Icons.assignment_turned_in_outlined),
                    size: 18
                  ),
                  label: Text(
                    request.status == 'completed' 
                        ? (isMyRequest ? '청소 완료 보고서 보기' : '내 평점보기')
                        : (request.status == 'in_progress' ? '청소 진행중' : '진행 상황 확인')
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: request.status == 'completed' 
                        ? Colors.green 
                        : (request.status == 'in_progress' ? Colors.blue : Color(0xFF1E88E5)),
                    side: BorderSide(
                      color: request.status == 'completed' 
                          ? Colors.green 
                          : (request.status == 'in_progress' ? Colors.blue : Color(0xFF1E88E5))
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            if (isAcceptedByMe && !isMyRequest && (request.status == 'pending' || request.status == 'accepted'))
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: request.paymentStatus == 'completed'
                      ? ElevatedButton.icon( // 결제 완료 시 청소 시작 가능
                          onPressed: () {
                            controller.startCleaning(request.id);
                          },
                          icon: Icon(Icons.cleaning_services, size: 18, color: Colors.white),
                          label: Text('청소 시작하기', 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        )
                      : ElevatedButton.icon( // 결제 대기중일 때
                          onPressed: null, // 비활성화
                          icon: Icon(Icons.hourglass_empty, size: 18, color: Colors.grey),
                          label: Text('결제 대기중', 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            padding: EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                        ),
                ),
              ),

             // 직접 의뢰받은 요청 수락하기 버튼 (아직 수락자가 없을 때)
            if (!isMyRequest && !isAccepted && request.targetStaffId == myUid)
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.acceptDirectRequest(request.id);
                    },
                    icon: Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                    label: Text('청소 수락하기', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // 수락은 초록색
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            if (isMyRequest && !isAccepted && request.applicants.isNotEmpty) ...[
              SizedBox(height: 16),
              Divider(),
              Text(
                '신청자 목록',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              ...request.applicants.map((applicantId) {
                // final controller usage removed as it is now passed
                return FutureBuilder<UserModel?>(
                  future: controller.getUserProfile(applicantId),
                  builder: (context, snapshot) {
                    final userProfile = snapshot.data;
                    final displayName = userProfile?.userName ?? applicantId;
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[400],
                            child: Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (userProfile?.address != null)
                                  Text(
                                    userProfile!.address!,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _showApplicantProfile(context, userProfile, applicantId, controller, request),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF1E88E5),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('확인/수락', style: TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ],
            // 신청 취소 버튼 (신청했지만 아직 수락되지 않은 경우)
            if (!isMyRequest && !isAccepted && request.applicants.contains(myUid))
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      controller.cancelApplication(request.id);
                    },
                    icon: Icon(Icons.cancel_outlined, size: 18),
                    label: Text('신청 취소', 
                      style: TextStyle(fontWeight: FontWeight.bold)
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }

  void _showApplicantProfile(BuildContext context, UserModel? userProfile, String applicantId, MyScheduleController controller, CleaningRequest request) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Profile header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF1E88E5),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile?.userName ?? '알 수 없음',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          userProfile?.userType == 'staff' ? '청소 전문가' : '청소 의뢰인',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              Divider(),
              SizedBox(height: 16),
              
              // Profile details
              if (userProfile != null) ...[
                _buildProfileRow(
                  icon: Icons.email,
                  label: '이메일',
                  value: userProfile.email,
                ),
                SizedBox(height: 16),
                
                if (userProfile.address != null && userProfile.address!.isNotEmpty) ...[
                  _buildProfileRow(
                    icon: Icons.location_on,
                    label: '주소',
                    value: userProfile.address!,
                  ),
                  SizedBox(height: 16),
                ],
                
                if (userProfile.userType == 'staff') ...[
                  // Staff Ratings & Reviews
                  FutureBuilder<Map<String, dynamic>>(
                    future: controller.getStaffRatingStats(userProfile.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return SizedBox.shrink();
                      final stats = snapshot.data!;
                      final averageRating = stats['averageRating'] ?? 0.0;
                      final reviewCount = stats['reviewCount'] ?? 0;
                      
                      return Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 24),
                              SizedBox(width: 8),
                               Text(
                                (averageRating as num).toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '($reviewCount개 후기)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          
                          // Recent Reviews
                          FutureBuilder<List<dynamic>>(
                            future: controller.getStaffRecentReviews(userProfile.id),
                            builder: (context, reviewSnapshot) {
                              if (!reviewSnapshot.hasData || reviewSnapshot.data!.isEmpty) {
                                return Text('아직 후기가 없습니다.', style: TextStyle(color: Colors.grey));
                              }
                              
                              final reviews = reviewSnapshot.data!;
                              final recentReviews = reviews.take(3).toList();
                              
                              return Column(
                                children: recentReviews.map((review) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: List.generate(5, (index) {
                                              return Icon(
                                                index < review.rating ? Icons.star : Icons.star_border,
                                                color: Colors.amber,
                                                size: 14,
                                              );
                                            }),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            review.comment,
                                            style: TextStyle(fontSize: 13),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ],
              ] else ...[
                 Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '프로필 정보를 불러올 수 없습니다',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ],
              
              SizedBox(height: 24),
              
              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (userProfile != null) {
                      controller.startChat(applicantId, userProfile.userName ?? '알 수 없음');
                    }
                  },
                  icon: Icon(Icons.chat_bubble_outline, size: 20),
                  label: Text('메시지 보내기'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Color(0xFF1E88E5),
                    side: BorderSide(color: Color(0xFF1E88E5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                   Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('닫기'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Close dialog first
                        Get.back();
                        // Proceed to Accept & Pay
                        if (userProfile != null) {
                           controller.acceptApplicant(applicantId, userProfile, request);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1E88E5),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('수락 및 결제', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Color(0xFF1E88E5),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
