import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';

class StaffSettlementController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<CleaningRequest> completedRequests = <CleaningRequest>[].obs;
  final RxInt totalAmount = 0.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettlementData();
  }

  void loadSettlementData() {
    final user = _auth.currentUser;
    if (user == null) {
      isLoading.value = false;
      return;
    }

    _repository.getMyCompletedRequestsAsStaff(user.uid).listen((requests) {
      completedRequests.assignAll(requests);
      _calculateTotalAmount();
      isLoading.value = false;
    });
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
