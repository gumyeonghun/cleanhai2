import 'package:get/get.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CleaningController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  final RxList<CleaningRequest> cleaningRequests = <CleaningRequest>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize data if needed, or bind streams
    bindCleaningRequests();
  }

  void bindCleaningRequests() {
    cleaningRequests.bindStream(_repository.getCleaningRequests());
  }

  // Add other methods as needed for HomePage, DetailPage, etc.
}
