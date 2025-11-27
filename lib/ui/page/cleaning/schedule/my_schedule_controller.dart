import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';

class MyScheduleController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<CleaningRequest> myAcceptedRequests = <CleaningRequest>[].obs;
  final RxList<CleaningRequest> myAppliedRequests = <CleaningRequest>[].obs;
  final RxBool isLoading = true.obs;

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

    // 의뢰자: 내가 의뢰한 것 중 수락된 것
    _repository.getMyAcceptedRequestsAsOwner(user.uid).listen((requests) {
      myAcceptedRequests.assignAll(requests);
    });

    // 청소 직원: 내가 신청한 모든 의뢰
    _repository.getMyAppliedRequestsAsStaff(user.uid).listen((requests) {
      myAppliedRequests.assignAll(requests);
      isLoading.value = false;
    });
  }

  Future<void> refresh() async {
    loadMySchedule();
  }
}
