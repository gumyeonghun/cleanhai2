import 'package:get/get.dart';
import 'package:cleanhai2/data/model/cleaning_staff.dart';
import 'package:cleanhai2/data/repository/cleaning_repository.dart';

class CleaningRankingController extends GetxController {
  final CleaningRepository _repository = CleaningRepository();

  final RxList<CleaningStaff> rankedStaffList = <CleaningStaff>[].obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, double> staffAverageRatings = <String, double>{}.obs;
  final RxMap<String, int> staffReviewCounts = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _fetchAndSortStaff();
  }

  Future<void> _fetchAndSortStaff() async {
    isLoading.value = true;
    try {
      // 1. Get all waiting staff
      // Note: In a real app, this might be inefficient. 
      // Ideally, 'averageRating' should be stored in the CleaningStaff document.
      final allStaff = await _repository.getWaitingStaff();
      
      List<CleaningStaff> staffWithRatings = [];

      // 2. Fetch ratings for each staff
      for (var staff in allStaff) {
        final stats = await _repository.getStaffRatingStats(staff.authorId);
        final avgRating = stats['averageRating'] as double;
        final reviewCount = stats['reviewCount'] as int;

        staffAverageRatings[staff.authorId] = avgRating;
        staffReviewCounts[staff.authorId] = reviewCount;

        // Only include staff in ranking if they have at least one review?
        // For now, include everyone, but sort by rating.
        staffWithRatings.add(staff);
      }

      // 3. Sort by Average Rating (Descending), then by Review Count (Descending)
      staffWithRatings.sort((a, b) {
        final ratingA = staffAverageRatings[a.authorId] ?? 0.0;
        final ratingB = staffAverageRatings[b.authorId] ?? 0.0;
        
        if (ratingA != ratingB) {
          return ratingB.compareTo(ratingA); // Higher rating first
        }
        
        final countA = staffReviewCounts[a.authorId] ?? 0;
        final countB = staffReviewCounts[b.authorId] ?? 0;
        return countB.compareTo(countA); // More reviews first
      });

      rankedStaffList.assignAll(staffWithRatings);

    } catch (e) {
      print('Error fetching ranking: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<CleaningStaff> getStaffByCategory(String category) {
    if (category == '전체') {
      return rankedStaffList;
    }
    return rankedStaffList.where((staff) => staff.cleaningType == category).toList();
  }
}
