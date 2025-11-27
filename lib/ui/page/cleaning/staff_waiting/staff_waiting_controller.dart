import 'package:get/get.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';

class StaffWaitingController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();
  
  final RxList<CleaningStaff> waitingStaff = <CleaningStaff>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadWaitingStaff();
  }

  Future<void> loadWaitingStaff() async {
    isLoading.value = true;
    try {
      final staff = await _repository.getWaitingStaff();
      waitingStaff.assignAll(staff);
    } catch (e) {
      print('Error loading waiting staff: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() async {
    await loadWaitingStaff();
  }
}
