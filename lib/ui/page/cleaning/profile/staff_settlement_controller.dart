import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';

class StaffSettlementController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<CleaningRequest> _allRequests = <CleaningRequest>[].obs; // 전체 데이터 저장
  final RxList<CleaningRequest> completedRequests = <CleaningRequest>[].obs; // 필터링된 데이터
  final RxInt totalAmount = 0.obs;
  final RxBool isLoading = true.obs;

  // 날짜 필터
  final Rx<DateTime> startDate = DateTime.now().obs;
  final Rx<DateTime> endDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    // 기본값: 이번 달 1일 ~ 오늘
    final now = DateTime.now();
    startDate.value = DateTime(now.year, now.month, 1);
    endDate.value = now;
    
    loadSettlementData();
  }

  void loadSettlementData() {
    final user = _auth.currentUser;
    if (user == null) {
      isLoading.value = false;
      return;
    }

    _repository.getMyCompletedRequestsAsStaff(user.uid).listen((requests) {
      _allRequests.assignAll(requests);
      _filterRequests(); // 데이터 로드 후 필터링 적용
      isLoading.value = false;
    });
  }

  void updateDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    // 종료일은 해당 날짜의 23:59:59까지 포함되도록 처리하거나, 비교 로직에서 처리
    endDate.value = end;
    _filterRequests();
  }

  void _filterRequests() {
    // 날짜 비교를 위해 시간 제거 (년, 월, 일만 비교)
    final start = DateTime(startDate.value.year, startDate.value.month, startDate.value.day);
    final end = DateTime(endDate.value.year, endDate.value.month, endDate.value.day, 23, 59, 59);

    final filtered = _allRequests.where((request) {
      return request.createdAt.isAfter(start.subtract(Duration(seconds: 1))) && 
             request.createdAt.isBefore(end.add(Duration(seconds: 1)));
    }).toList();

    completedRequests.assignAll(filtered);
    _calculateTotalAmount();
  }

  void _calculateTotalAmount() {
    int total = 0;
    for (var request in completedRequests) {
      if (request.price != null) {
        // 가격 문자열에서 숫자만 추출 (예: "50,000" -> 50000)
        String priceStr = request.price!.replaceAll(RegExp(r'[^0-9]'), '');
        int? price = int.tryParse(priceStr);
        if (price != null) {
          total += price;
        }
      }
    }
    totalAmount.value = total;
  }
}
