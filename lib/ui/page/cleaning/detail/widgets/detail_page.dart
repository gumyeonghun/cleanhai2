import 'package:cleanhai2/ui/page/chat/chat_room_page.dart';
import 'package:cleanhai2/data/repository/chat_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import 'package:cleanhai2/data/model/user_model.dart';
import '../../write/widgets/write_page.dart';
import '../../report/widgets/completion_report_view_page.dart';
import '../detail_controller.dart';
import 'staff_review_list_page.dart';


class DetailPage extends StatelessWidget {
  final CleaningRequest? cleaningRequest;
  final CleaningStaff? cleaningStaff;

  const DetailPage({
    super.key,
    this.cleaningRequest,
    this.cleaningStaff,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DetailController(
      initialRequest: cleaningRequest,
      initialStaff: cleaningStaff,
    ), tag: cleaningRequest?.id ?? cleaningStaff?.id); 
    // Use tag to allow multiple DetailPages for different items if needed

    return Scaffold(
      appBar: AppBar(
        actions: [
          Obx(() {
            if (!controller.isAuthor.value) {
              return Row(
                children: [
                  _iconButton(Icons.message, () async {
                    final myUser = FirebaseAuth.instance.currentUser;
                    if (myUser == null) return;

                    // 작성자 정보 가져오기
                    final authorId = cleaningRequest?.authorId ?? cleaningStaff?.authorId ?? '';
                    final authorName = cleaningRequest?.authorName ?? cleaningStaff?.authorName ?? '알 수 없음';
                    
                    if (authorId.isEmpty) {
                      Get.snackbar('조회 실패', '상대방의 정보를 불러올 수 없습니다.');
                      return;
                    }

                    try {
                      // 내 이름 가져오기
                      final myUserData = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(myUser.uid)
                          .get();
                      final myName = myUserData.data()?['userName'] ?? '사용자';

                      // 채팅방 생성 또는 가져오기
                      final chatRoom = await ChatRepository().getOrCreateChatRoom(
                        myUser.uid,
                        authorId,
                        myName,
                        authorName,
                      );

                      // 채팅방으로 이동
                      Get.to(() => ChatRoomPage(chatRoom: chatRoom));
                    } catch (e) {
                      Get.snackbar('오류', '채팅방을 생성할 수 없습니다: $e');
                    }
                  }),
                  // Report / Block Menu
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    onSelected: (value) {
                      if (value == 'report') {
                        controller.reportItem(); // Call controller method
                      } else if (value == 'block') {
                        controller.blockUser(); // Call controller method
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('신고하기', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'block',
                        child: Row(
                          children: [
                            Icon(Icons.block_outlined, color: Colors.grey, size: 20),
                            SizedBox(width: 8),
                            Text('차단하기'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return SizedBox.shrink();
          }),
          Obx(() {
            if (controller.isAuthor.value) {
              return Row(
                children: [
                    _iconButton(Icons.delete, () {
                      controller.deleteItem();
                    }),
                    _iconButton(Icons.edit, () {
                      Get.to(() => WritePage(
                        existingRequest: controller.currentRequest.value,
                        existingStaff: cleaningStaff,
                      ));
                    }),
                ],
              );
            }
            return SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        final imageUrl = controller.imageUrl;
        final title = controller.title;
        final authorName = controller.authorName;
        final createdAt = controller.createdAt;
        final price = controller.price;
        final content = controller.content;
        final currentRequest = controller.currentRequest.value;
        final isAuthor = controller.isAuthor.value;
        final hasApplied = controller.hasApplied;
        final additionalOptionCost = controller.additionalOptionCost;
        final cleaningType = controller.cleaningType;
        final currentUser = FirebaseAuth.instance.currentUser;

        return ListView(
          padding: EdgeInsets.only(bottom: 300),
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Icon(Icons.broken_image, size: 50),
                  );
                },
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: Icon(Icons.image, size: 50, color: Colors.grey[600]),
              ),
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 15),
                  Text(
                    authorName,
                    style: TextStyle(fontSize: 15),
                  ),
                  Obx(() {
                    if (controller.authorProfile.value != null && 
                        controller.authorProfile.value!.email.isNotEmpty &&
                        controller.authorProfile.value!.email != authorName) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          controller.authorProfile.value!.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  }),
                  SizedBox(height: 5),
                  
                  // 평점 및 리뷰 수 (청소 전문가인 경우)
                  if (cleaningStaff != null)
                    Obx(() {
                      final ratings = controller.staffRating;
                      if (ratings.isNotEmpty && ratings['reviewCount'] != null && ratings['reviewCount'] > 0) {
                        final avgRating = (ratings['averageRating'] as num).toDouble();
                        final reviewCount = ratings['reviewCount'] as int;
                        return GestureDetector(
                          onTap: () {
                            // 리뷰 목록 페이지로 이동
                            Get.to(() => StaffReviewListPage(
                              staffId: cleaningStaff!.authorId,
                              staffName: cleaningStaff!.authorName,
                              ratingStats: ratings,
                              reviewRequests: controller.staffReviewRequests,
                            ));
                          },
                          child: Container(
                            margin: EdgeInsets.only(top: 8, bottom: 8),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 18, color: Colors.amber),
                                SizedBox(width: 6),
                                Text(
                                  avgRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '($reviewCount개 리뷰)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right, size: 18, color: Colors.grey[600]),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Container(
                          margin: EdgeInsets.only(top: 8, bottom: 8),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_border, size: 18, color: Colors.grey[400]),
                              SizedBox(width: 6),
                              Text(
                                '리뷰 없음',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }),
                  
                  Text(
                    DateFormat('yyyy.MM.dd HH:mm').format(createdAt),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w200),
                  ),
                  
                  // 청소 금액 표시 (청소 의뢰일 때만)
                  if (price != null && price.isNotEmpty) ...[
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF1E88E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF1E88E5).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.payments, color: Color(0xFF1E88E5)),
                          SizedBox(width: 12),
                          Text(
                            '청소 금액: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              () {
                                final parsedPrice = int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), ''));
                                if (parsedPrice != null && parsedPrice > 0) {
                                  return '${NumberFormat('#,###').format(parsedPrice)}원';
                                }
                                return price;
                              }(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E88E5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // 청소 날짜 및 시간 표시 (청소 의뢰일 때만, cleaningDate가 있을 때)
                  if (currentRequest?.cleaningDate != null) ...[
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.orange),
                          SizedBox(width: 12),
                          Text(
                            '청소 일시: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              DateFormat('yyyy년 MM월 dd일 HH:mm').format(currentRequest!.cleaningDate!),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // 청소 필요 기간 (청소 의뢰일 때만)
                  if (currentRequest?.cleaningDuration != null && currentRequest!.cleaningDuration!.isNotEmpty) ...[
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timelapse, color: Colors.purple),
                          SizedBox(width: 12),
                          Text(
                            '청소 기간: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              currentRequest.cleaningDuration ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 청소 장소 (청소 의뢰일 때만)
                  if (currentRequest != null && currentRequest.address != null && currentRequest.address!.isNotEmpty) ...[
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, color: Colors.blueGrey),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '청소 장소',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${currentRequest.address!} ${currentRequest.detailAddress ?? ''}'.trim(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // 추가옵션 비용 표시 (청소 전문가일 때만)
                  if (additionalOptionCost != null && additionalOptionCost.isNotEmpty) ...[
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.add_circle_outline, color: Colors.green),
                              SizedBox(width: 12),
                              Text(
                                '추가옵션 비용',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            additionalOptionCost,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Activity Area (Address)
                  if (cleaningStaff != null && cleaningStaff!.address != null && cleaningStaff!.address!.isNotEmpty) ...[
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blueGrey),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '활동 지역',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  cleaningStaff!.address!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 근무 가능 요일 및 시간 (청소 전문가인 경우)
                  if (cleaningStaff != null) ...[
                    // 근무 가능 기간
                    if (cleaningStaff!.cleaningDuration != null && cleaningStaff!.cleaningDuration!.isNotEmpty) ...[
                      SizedBox(height: 15),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timelapse, color: Colors.purple),
                            SizedBox(width: 12),
                            Text(
                              '근무 가능 기간: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                cleaningStaff!.cleaningDuration!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (cleaningStaff!.availableDays != null && cleaningStaff!.availableDays!.isNotEmpty) ...[
                      SizedBox(height: 15),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.purple),
                                SizedBox(width: 12),
                                Text(
                                  '근무 가능 요일',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              cleaningStaff!.availableDays!.join(', '),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (cleaningStaff!.availableStartTime != null && cleaningStaff!.availableEndTime != null) ...[
                      SizedBox(height: 15),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.orange),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '근무 가능 시간',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${cleaningStaff!.availableStartTime} ~ ${cleaningStaff!.availableEndTime}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  
                  // 청소 종류 표시
                  if (cleaningType != null && cleaningType.isNotEmpty) ...[
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF1E88E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF1E88E5).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cleaning_services, color: Color(0xFF1E88E5)),
                          SizedBox(width: 12),
                          Text(
                            '청소종류: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFF1E88E5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cleaningType,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  SizedBox(height: 15),
                  Text(
                    content,
                    style: TextStyle(fontSize: 15),
                  ),

                  // 추가 정보 표시 (청소 의뢰일 때만)
                  if (currentRequest != null) ...[
                    if (currentRequest.requesterName != null && currentRequest.requesterName!.isNotEmpty) ...[
                      SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.person, size: 20, color: Color(0xFF1E88E5)),
                          SizedBox(width: 8),
                          Text(
                            '의뢰인: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              fontSize: 15,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              currentRequest.requesterName!,
                              style: TextStyle(fontSize: 15, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ],


                  ],
                  
                  

                  
                  // 청소 신청 버튼 (청소 의뢰이고, 작성자가 아닐 때)
                  // 청소 전문가 대기글인 경우 (의뢰하기 기능)
                  if (cleaningStaff != null && currentRequest == null && !isAuthor && currentUser != null) ...[
                     // 청소 전문가 대기글인 경우 (의뢰하기 기능)
                     SizedBox(height: 24),
                     Obx(() {
                        final status = controller.existingRequestStatus.value;
                        if (status == 'pending') {
                           return Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Text(
                              '청소의뢰대기중',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          );
                        } else if (status == 'accepted') {
                           return Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Text(
                              '청소 결제대기중', // Or matched
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          );
                        } else {
                          // 신청 가능
                           return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: controller.requestCleaningFromStaff,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1E88E5),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                '청소 의뢰하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }
                     }),
                  ],
                  
                  // 청소 신청 아이템 로직 (청소 전문가, 혹은 청소 의뢰)
                  if (currentRequest != null && !isAuthor && currentUser != null) ...[
                    SizedBox(height: 24),
                    // Direct Request Acceptance (Staff)
                    if (currentRequest.targetStaffId == currentUser.uid && currentRequest.status == 'pending') ...[
                      if (currentRequest.acceptedApplicantId == currentUser.uid)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '결제대기중',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.acceptRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF1E88E5),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              '의뢰 수락하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ] else if (currentRequest.status == 'accepted' && currentRequest.acceptedApplicantId == currentUser.uid) ...[
                      // Start Cleaning (Staff)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.startCleaning,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1E88E5),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '청소 시작하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ] else if (currentRequest.status == 'in_progress' && currentRequest.acceptedApplicantId == currentUser.uid) ...[
                       Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Text(
                          '청소 진행중',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ] else ...[
                      // Normal Application
                      if (controller.currentUserType.value == 'staff')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: hasApplied ? null : controller.applyForJob,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasApplied ? Colors.grey : Color(0xFF1E88E5),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              hasApplied ? '신청 완료' : '청소 신청하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],

                  // Owner sees status banner for Pending/Accepted/InProgress requests to Staff
                  if (currentRequest != null && isAuthor && currentUser != null) ...[
                     if (currentRequest.status == 'pending') ...[
                        SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Text(
                            '청소의뢰대기중',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                     ] else if (currentRequest.targetStaffId != null && 
                         currentRequest.acceptedApplicantId != null && 
                         currentRequest.paymentStatus != 'completed') ...[
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.processPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF1E88E5),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              '결제하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                     ] else if (currentRequest.status == 'accepted') ...[
                        SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Color(0xFF1E88E5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xFF1E88E5)),
                          ),
                          child: Text(
                            '매칭 완료 (청소 대기중)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E88E5),
                            ),
                          ),
                        ),
                     ] else if (currentRequest.status == 'in_progress') ...[
                        SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Text(
                            '청소 진행중',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        ],
                   ],
                   
                   // 청소 완료 보고서 보기 버튼 (완료된 상태이고 보고서가 있을 때)
                   if (currentRequest != null && 
                       currentRequest.completionReport != null && 
                       (isAuthor || currentRequest.acceptedApplicantId == currentUser?.uid)) ...[
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Get.to(() => CompletionReportViewPage(
                              report: currentRequest.completionReport!,
                              requestId: currentRequest.id,
                              canReview: isAuthor && currentRequest.review == null,
                              review: currentRequest.review,
                            ));
                          },
                          icon: Icon(Icons.assignment_turned_in, color: Color(0xFF1E88E5)),
                          label: Text('청소 완료 보고서 보기'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Color(0xFF1E88E5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: Color(0xFF1E88E5),
                          ),
                        ),
                      ),
                   ],
                                    // 청소 전문가 프로필 보기일 때 의뢰하기 버튼 (의뢰인만 가능)
                   // 신청자 목록 (작성자일 때만)

                  
                   // 신청자 목록 (작성자일 때만)
                  if (currentRequest != null && isAuthor && currentRequest.applicants.isNotEmpty) ...[
                    SizedBox(height: 24),
                    Text(
                      '신청자 목록',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),

                    SizedBox(height: 12),
                    ...(currentRequest.applicants.map((applicantId) {
                      final isAccepted = currentRequest.acceptedApplicantId == applicantId;
                      
                      return FutureBuilder<UserModel?>(
                        future: controller.getUserProfile(applicantId),
                        builder: (context, snapshot) {
                          final userProfile = snapshot.data;
                          final displayName = userProfile?.userName ?? applicantId;
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isAccepted ? Color(0xFF1E88E5).withValues(alpha: 0.1) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAccepted ? Color(0xFF1E88E5) : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _showApplicantProfile(context, userProfile, applicantId, controller),
                                    behavior: HitTestBehavior.opaque,
                                    child: Row(
                                      children: [
                                        // Profile icon (no photo in UserModel)
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isAccepted ? Color(0xFF1E88E5) : Colors.grey[400],
                                          child: Icon(
                                            isAccepted ? Icons.check_circle : Icons.person,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      displayName,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: isAccepted ? FontWeight.bold : FontWeight.w600,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.info_outline,
                                                    size: 16,
                                                    color: Colors.grey[500],
                                                  ),
                                                ],
                                              ),
                                              if (userProfile?.address != null && userProfile!.address!.isNotEmpty) ...[
                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                                                    SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        userProfile.address!,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                if (!isAccepted)
                                  ElevatedButton(
                                    onPressed: () => controller.acceptApplicant(applicantId, userProfile),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF1E88E5),
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      '수락',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF1E88E5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '수락됨',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    }).toList()),
                  ],
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _iconButton(IconData icon, void Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        color: Colors.transparent,
        child: Icon(icon),
      ),
    );
  }

  void _showApplicantProfile(BuildContext context, UserModel? userProfile, String applicantId, DetailController controller) {
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
                          GestureDetector(
                            onTap: () async {
                              if (reviewCount > 0) {
                                final requests = await controller.getStaffCleaningHistory(userProfile.id);
                                Get.to(() => StaffReviewListPage(
                                  staffId: userProfile.id,
                                  staffName: userProfile.userName ?? '알 수 없음',
                                  ratingStats: stats,
                                  reviewRequests: requests,
                                ));
                              }
                            },
                            child: Row(
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
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                              ],
                            ),
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
                  
                  _buildProfileRow(
                    icon: Icons.badge,
                    label: '회원 유형',
                    value: userProfile.userType == 'staff' ? '청소 전문가' : '청소 의뢰인',
                  ),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '프로필 정보를 불러올 수 없습니다',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
                
                SizedBox(height: 24),

                // Message Button
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
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '닫기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
}
