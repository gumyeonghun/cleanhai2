import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cleanhai2/data/model/cleaning_request.dart';

class StaffReviewListPage extends StatelessWidget {
  final String staffId;
  final String staffName;
  final Map<String, dynamic> ratingStats;
  final List<CleaningRequest> reviewRequests;

  const StaffReviewListPage({
    super.key,
    required this.staffId,
    required this.staffName,
    required this.ratingStats,
    required this.reviewRequests,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out requests that don't have a review
    final filteredReviews = reviewRequests.where((r) => r.review != null).toList();

    final avgRating = ratingStats['averageRating'] != null 
        ? (ratingStats['averageRating'] as num).toDouble() 
        : 0.0;
    final reviewCount = ratingStats['reviewCount'] ?? 0;
    
    // Calculate rating distribution
    // Calculate rating distribution
    Map<int, int> ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    if (ratingStats['distribution'] != null) {
      final dist = ratingStats['distribution'] as Map<dynamic, dynamic>;
      dist.forEach((key, value) {
        if (key is int && value is int) {
          ratingDistribution[key] = value;
        }
      });
    } else {
      // Fallback if not available
      for (var request in filteredReviews) {
        if (request.review != null) {
          final rating = (request.review?.rating ?? 0).round();
          if (rating >= 1 && rating <= 5) {
            ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
          }
        }
      }
    }

    // Extract detailed ratings
    final communicationRating = ratingStats['communicationRating'] != null 
        ? (ratingStats['communicationRating'] as num).toDouble() : 0.0;
    final qualityRating = ratingStats['qualityRating'] != null 
        ? (ratingStats['qualityRating'] as num).toDouble() : 0.0;
    final reliabilityRating = ratingStats['reliabilityRating'] != null 
        ? (ratingStats['reliabilityRating'] as num).toDouble() : 0.0;
    final priceRating = ratingStats['priceRating'] != null 
        ? (ratingStats['priceRating'] as num).toDouble() : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '$staffName님의 리뷰',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // 평점 요약 카드 (리뷰가 있을 때만 표시)
                  if (reviewCount > 0)
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left side - Overall rating
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Icon(Icons.star, size: 40, color: Colors.amber),
                                  SizedBox(height: 8),
                                  Text(
                                    avgRating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '총 $reviewCount개의 리뷰',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(width: 24),
                            
                            // Right side - Rating distribution
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  for (int star = 5; star >= 1; star--)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Text(
                                            '$star',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.star, size: 14, color: Colors.amber),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Stack(
                                              children: [
                                                Container(
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                                FractionallySizedBox(
                                                  widthFactor: reviewCount > 0 
                                                      ? (ratingDistribution[star] ?? 0) / reviewCount 
                                                      : 0.0,
                                                  child: Container(
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          SizedBox(
                                            width: 30,
                                            child: Text(
                                              '${ratingDistribution[star] ?? 0}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                ),
                                              textAlign: TextAlign.end,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Divider(height: 1, color: Colors.grey[200]),
                        SizedBox(height: 20),
                        // Detailed Ratings Breakdown
                        _buildDetailRatingRow('소통', communicationRating),
                        SizedBox(height: 12),
                        _buildDetailRatingRow('품질', qualityRating),
                        SizedBox(height: 12),
                        _buildDetailRatingRow('약속', reliabilityRating),
                        SizedBox(height: 12),
                        _buildDetailRatingRow('가격', priceRating),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // 완료된 청소 목록
                  Text(
                    '완료된 청소 목록',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Clean list (including unreviewed ones)
                  if (filteredReviews.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.cleaning_services_outlined, size: 64, color: Colors.grey[300]),
                          SizedBox(height: 16),
                          Text(
                            '아직 작성된 리뷰가 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: filteredReviews.length,
                      separatorBuilder: (context, index) => SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final request = filteredReviews[index];
                        final hasReview = request.review != null;
                        
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
                              // Header with title and rating
                              Row(
                                children: [
                                  // ... title text ...
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          request.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        if (request.address != null)
                                          Row(
                                            children: [
                                              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                                              SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  request.address ?? '',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  // Star rating or No Review Badge
                                  if (hasReview)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star, size: 16, color: Colors.amber),
                                          SizedBox(width: 4),
                                          Text(
                                            (request.review?.rating ?? 0.0).toStringAsFixed(1),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '리뷰 없음',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              
                              if (hasReview) ...[
                                SizedBox(height: 12),
                                // Detailed Ratings in Card
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildSmallRatingItem('소통', request.review?.communicationRating),
                                      _buildSmallRatingItem('품질', request.review?.qualityRating),
                                      _buildSmallRatingItem('약속', request.review?.reliabilityRating),
                                      _buildSmallRatingItem('가격', request.review?.priceRating),
                                    ],
                                  ),
                                ),
                                
                                if (request.review?.comment.isNotEmpty == true) ...[
                                  SizedBox(height: 12),
                                  Text(
                                    request.review?.comment ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ],
                              
                              // Date
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
                                  SizedBox(width: 6),
                                  Text(
                                    DateFormat('yyyy.MM.dd HH:mm').format(
                                      (hasReview && request.review != null) 
                                          ? (request.review?.createdAt ?? DateTime.now()) 
                                          : (request.completedAt ?? request.updatedAt)
                                    ),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRatingRow(String label, double rating) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700]))),
        SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: rating / 5.0,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        SizedBox(
          width: 30,
          child: Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 13,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallRatingItem(String label, double? rating) {
    final val = rating ?? 0.0;
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        SizedBox(height: 2),
        Row(
          children: [
            Icon(Icons.star, size: 10, color: Colors.amber),
            SizedBox(width: 2),
            Text(val.toStringAsFixed(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
