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
import '../detail_controller.dart';

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
          Text(
            '대화하기',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          _iconButton(Icons.message, () async {
            final myUser = FirebaseAuth.instance.currentUser;
            if (myUser == null) return;

            // 작성자 정보 가져오기
            final authorId = cleaningRequest?.authorId ?? cleaningStaff?.authorId ?? '';
            final authorName = cleaningRequest?.authorName ?? cleaningStaff?.authorName ?? '알 수 없음';
            
            if (authorId.isEmpty) return;

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
          }),
          Obx(() {
            if (controller.isAuthor) {
              return Row(
                children: [
                  _iconButton(Icons.delete, () {
                    controller.deleteItem();
                  }),
                  _iconButton(Icons.edit, () {
                    Get.to(() => WritePage(
                      existingRequest: controller.currentRequest.value,
                      existingStaff: cleaningStaff, // Staff edit might need controller support too
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
        final isAuthor = controller.isAuthor;
        final hasApplied = controller.hasApplied;
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
                  SizedBox(height: 5),
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
                        color: Color(0xFFE53935).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE53935).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.payments, color: Color(0xFFE53935)),
                          SizedBox(width: 12),
                          Text(
                            '청소 금액: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            '${NumberFormat('#,###').format(int.tryParse(price) ?? 0)}원',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE53935),
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
                  
                  // 청소 신청 버튼 (청소 의뢰이고, 작성자가 아닐 때)
                  if (currentRequest != null && !isAuthor && currentUser != null) ...[
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: hasApplied ? null : controller.applyForJob,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasApplied ? Colors.grey : Color(0xFFE53935),
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
                          final displayName = userProfile?.email ?? applicantId;
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isAccepted ? Color(0xFFE53935).withValues(alpha: 0.1) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAccepted ? Color(0xFFE53935) : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _showApplicantProfile(context, userProfile, applicantId),
                                    behavior: HitTestBehavior.opaque,
                                    child: Row(
                                      children: [
                                        // Profile icon (no photo in UserModel)
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: isAccepted ? Color(0xFFE53935) : Colors.grey[400],
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
                                      backgroundColor: Color(0xFFE53935),
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
                                      color: Color(0xFFE53935),
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

  void _showApplicantProfile(BuildContext context, UserModel? userProfile, String applicantId) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFE53935),
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
                          '청소 직원 프로필',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          userProfile?.userType == 'staff' ? '청소 직원' : '숙박업소',
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
                
                if (userProfile.latitude != null && userProfile.longitude != null) ...[
                  _buildProfileRow(
                    icon: Icons.map,
                    label: '위치',
                    value: '위도: ${userProfile.latitude!.toStringAsFixed(4)}, 경도: ${userProfile.longitude!.toStringAsFixed(4)}',
                  ),
                  SizedBox(height: 16),
                ],
                
                _buildProfileRow(
                  icon: Icons.badge,
                  label: '회원 유형',
                  value: userProfile.userType == 'staff' ? '청소 직원' : '숙박업소',
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
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE53935),
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
          color: Color(0xFFE53935),
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
