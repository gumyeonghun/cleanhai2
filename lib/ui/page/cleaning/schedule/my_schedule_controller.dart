import 'package:cleanhai2/data/repository/chat_repository.dart';
import 'package:cleanhai2/ui/page/chat/chat_room_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import 'package:cleanhai2/data/model/user_model.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';
import 'package:cleanhai2/ui/page/cleaning/payment/payment_selection_page.dart';
import 'package:uuid/uuid.dart';

class MyScheduleController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<CleaningRequest> myAcceptedRequests = <CleaningRequest>[].obs;
  final RxList<CleaningRequest> myAppliedRequests = <CleaningRequest>[].obs;
  final RxList<CleaningRequest> myTargetedRequests = <CleaningRequest>[].obs;
  final Rx<CleaningStaff?> myWaitingProfile = Rx<CleaningStaff?>(null);
  final RxBool isLoading = true.obs;
  
  // 이전에 확인한 요청 ID들을 저장
  final RxList<String> _previousAcceptedIds = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMySchedule();
  }

  void loadMySchedule() {
    final user = _auth.currentUser;
    if (user == null) {
      isLoading.value = false;
      return;
    }

    // 의뢰자: 내가 의뢰한 모든 것 (대기중 + 수락됨)
    _repository.getAllMyRequestsAsOwner(user.uid).listen((requests) {
      myAcceptedRequests.assignAll(requests);
    });

    // 청소 직원: 내가 신청한 모든 의뢰
    _repository.getMyAppliedRequestsAsStaff(user.uid).listen((requests) {
      // 새로 수락된 요청 확인
      final acceptedRequests = requests.where((r) => r.status == 'accepted').toList();
      final newAcceptedIds = acceptedRequests.map((r) => r.id).toSet();
      
      // 이전에 없던 새로운 매칭 확인
      if (_previousAcceptedIds.isNotEmpty) {
        final newMatches = newAcceptedIds.difference(_previousAcceptedIds.toSet());
        if (newMatches.isNotEmpty) {
          // 새로운 매칭이 있으면 알림 표시
          for (var requestId in newMatches) {
            final request = acceptedRequests.firstWhere((r) => r.id == requestId);
            Get.snackbar(
              '매칭 완료!',
              '${request.authorName}님의 청소 의뢰가 수락되었습니다!\n일정을 확인해주세요.',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: Duration(seconds: 5),
              snackPosition: SnackPosition.TOP,
              icon: Icon(Icons.check_circle, color: Colors.white),
            );
          }
        }
      }
      
      // 현재 수락된 요청 ID 저장
      _previousAcceptedIds.assignAll(newAcceptedIds.toList());
      
      myAppliedRequests.assignAll(requests);
    });

    // 청소 직원: 나에게 직접 들어온 의뢰
    _repository.getMyTargetedRequestsAsStaff(user.uid).listen((requests) {
      myTargetedRequests.assignAll(requests);
      // 로딩 완료 처리는 여기서 (마지막 스트림) - 간단하게 처리
      Future.delayed(Duration(milliseconds: 500), () {
        isLoading.value = false; 
      });
    });

    // 청소 직원: 내 대기 프로필 (청소 대기 목록에 등록한 것)
    _repository.getMyWaitingProfileStream(user.uid).listen((profile) {
      myWaitingProfile.value = profile;
    });
  }

  Future<void> startCleaning(String requestId) async {
    // 예상 완료 시간 입력 다이얼로그 표시
    final TimeOfDay? selectedTime = await Get.dialog<TimeOfDay>(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '청소 예상 완료 시간',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '청소가 완료될 예상 시간을 선택해주세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final TimeOfDay? time = await showTimePicker(
                    context: Get.context!,
                    initialTime: TimeOfDay.now(),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Color(0xFF1E88E5),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    Get.back(result: time);
                  }
                },
                icon: Icon(Icons.access_time, color: Colors.white),
                label: Text('시간 선택', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E88E5),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextButton(
                onPressed: () => Get.back(),
                child: Text('취소', style: TextStyle(color: Colors.grey[600])),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedTime == null) {
      // 사용자가 취소한 경우
      return;
    }

    try {
      // 선택한 시간을 DateTime으로 변환
      final now = DateTime.now();
      final estimatedCompletion = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // 만약 선택한 시간이 현재 시간보다 이전이면 다음 날로 설정
      final finalEstimatedTime = estimatedCompletion.isBefore(now)
          ? estimatedCompletion.add(Duration(days: 1))
          : estimatedCompletion;

      // Firestore 업데이트
      await FirebaseFirestore.instance
          .collection('cleaning_requests')
          .doc(requestId)
          .update({
        'status': 'in_progress',
        'startedAt': Timestamp.fromDate(DateTime.now()),
        'estimatedCompletionTime': Timestamp.fromDate(finalEstimatedTime),
      });

      Get.snackbar(
        '청소 시작',
        '청소가 시작되었습니다.\\n예상 완료 시간: ${selectedTime.format(Get.context!)}',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );

      // 목록 새로고침
      loadMySchedule();
    } catch (e) {
      Get.snackbar(
        '오류',
        '상태 변경 중 오류가 발생했습니다: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> processPayment(CleaningRequest request) async {
    if (request.acceptedApplicantId == null) {
      Get.snackbar('오류', '수락된 신청자가 없습니다.');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar('알림', '로그인이 필요합니다');
      return;
    }

    try {
      Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);
      
      final staffProfile = await _repository.getUserProfile(request.acceptedApplicantId!);
      
      Get.back(); // Close loading

      if (staffProfile == null) {
        Get.snackbar('오류', '신청자 정보를 불러올 수 없습니다.');
        return;
      }

      if (request.price == null || request.price!.isEmpty || request.price == '0' || request.price == '0원') {
        Get.snackbar('오류', '청소 금액이 설정되지 않았습니다.');
        return;
      }

      final result = await Get.to(() => PaymentSelectionPage(
        applicant: staffProfile,
        price: request.price!,
        orderName: request.title,
        orderId: Uuid().v4(),
        customerEmail: currentUser.email!,
      ));

      if (result != null && result['success'] == true) {
        Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);

        if (result['isFree'] == true) {
          final paymentKey = 'free_match_${Uuid().v4()}';
          final orderId = result['orderId'] ?? Uuid().v4();

          await _repository.acceptApplicant(
            request.id,
            request.acceptedApplicantId!,
            paymentKey: paymentKey,
            orderId: orderId,
            paymentStatus: 'completed',
          );
          
          await _repository.updateCleaningStatus(request.id, 'accepted');

          Get.back(); // Close loading

          Get.snackbar(
            '매칭 완료!',
            '${staffProfile.userName ?? "청소 전문가"}님과 무료 매칭되었습니다.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          
          loadMySchedule();
          return;
        }

        // Handle paid payment
        final successData = result['data'];
        final paymentKey = successData.paymentKey;
        final orderId = successData.orderId;
        final amount = successData.amount;

        final confirmResult = await _repository.confirmPayment(
          paymentKey: paymentKey,
          orderId: orderId,
          amount: (amount is int) ? amount : (amount as num).toInt(),
        );

        if (confirmResult['success'] == true) {
          await _repository.acceptApplicant(
            request.id,
            request.acceptedApplicantId!,
            paymentKey: paymentKey,
            orderId: orderId,
            paymentStatus: 'completed',
          );

          await _repository.updateCleaningStatus(request.id, 'accepted');

          Get.back(); // Close loading

          Get.snackbar(
            '결제 완료!',
            '${staffProfile.userName ?? "청소 전문가"}님과 매칭되었습니다.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          
          loadMySchedule();
        } else {
           Get.back(); // Close loading
           Get.snackbar('결제 승인 실패', '결제 요청은 성공했으나 최종 승인에 실패했습니다.\n${confirmResult['error']}');
        }
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('오류', '결제 처리 중 오류가 발생했습니다: $e');
    }
  }

  Future<UserModel?> getUserProfile(String uid) {
    return _repository.getUserProfile(uid);
  }

  Future<Map<String, dynamic>> getStaffRatingStats(String staffId) {
    return _repository.getStaffRatingStats(staffId);
  }

  Future<List<dynamic>> getStaffRecentReviews(String staffId) async {
    final requests = await _repository.getCompletedCleaningHistory(staffId);
    return requests
        .where((r) => r.review != null)
        .map((r) => r.review!)
        .toList();
  }

  Future<void> acceptApplicant(String applicantId, UserModel applicantProfile, CleaningRequest request) async {
    if (request.price == null || request.price!.isEmpty) {
      Get.snackbar('알림', '청소 금액이 설정되지 않았습니다');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.snackbar('알림', '로그인이 필요합니다');
      return;
    }

    final result = await Get.to(() => PaymentSelectionPage(
      applicant: applicantProfile,
      price: request.price!,
      orderName: request.title,
      orderId: Uuid().v4(),
      customerEmail: currentUser.email!,
    ));

    if (result != null && result['success'] == true) {
      try {
        Get.dialog(Center(child: CircularProgressIndicator()), barrierDismissible: false);
        
        final paymentKey = result['data']?.paymentKey ?? 'toss_payment_${DateTime.now().millisecondsSinceEpoch}';
        final orderId = result['data']?.orderId ?? result['orderId'] ?? Uuid().v4();

        // 무료 매칭인 경우 바로 서버 승인 없이 처리 (혹은 무료 승인 로직에 따름)
        if (result['isFree'] == true) {
           await _repository.acceptApplicant(
            request.id,
            applicantId,
            paymentKey: paymentKey,
            orderId: orderId,
            paymentStatus: 'completed',
          );
           await _repository.updateCleaningStatus(request.id, 'accepted');
        } else {
             // 유료 결제인 경우 서버 승인 필요
            final amount = result['data']?.amount;
             final confirmResult = await _repository.confirmPayment(
              paymentKey: paymentKey,
              orderId: orderId,
              amount: (amount is int) ? amount : (amount as num).toInt(),
            );
            
            if (confirmResult['success'] != true) {
               Get.back(); 
               Get.snackbar('결제 승인 실패', '결제 요청은 성공했으나 최종 승인에 실패했습니다.\n${confirmResult['error']}');
               return;
            }

             await _repository.acceptApplicant(
              request.id,
              applicantId,
              paymentKey: paymentKey,
              orderId: orderId,
              paymentStatus: 'completed',
            );
             await _repository.updateCleaningStatus(request.id, 'accepted');
        }

        Get.back(); // Close loading
        
        Get.snackbar(
          '매칭 완료!',
          '${applicantProfile.userName ?? "청소 전문가"}님과 매칭되었습니다.\n청소 일정을 확인해주세요.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
          snackPosition: SnackPosition.TOP,
          icon: Icon(Icons.check_circle, color: Colors.white),
        );
        
        loadMySchedule();
      } catch (e) {
        if (Get.isDialogOpen ?? false) Get.back(); 
        Get.snackbar('오류', '매칭 처리 중 오류가 발생했습니다: $e');
      }
    }
  }

  Future<void> startChat(String targetUserId, String targetUserName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      Get.snackbar('알림', '로그인이 필요합니다');
      return;
    }

    try {
      // 내 이름 가져오기
      final myUserData = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final myName = myUserData.data()?['userName'] ?? '사용자';

      // 채팅방 생성 또는 가져오기
      final chatRoom = await ChatRepository().getOrCreateChatRoom(
        currentUser.uid,
        targetUserId,
        myName,
        targetUserName,
      );

      // 채팅방으로 이동
      Get.to(() => ChatRoomPage(chatRoom: chatRoom));
    } catch (e) {
      Get.snackbar('오류', '채팅방 연결 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Future<void> refresh() async {
    loadMySchedule();
  }
}
