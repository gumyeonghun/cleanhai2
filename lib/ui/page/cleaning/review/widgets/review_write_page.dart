import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../review_controller.dart';

class ReviewWritePage extends StatelessWidget {
  final String requestId;

  const ReviewWritePage({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReviewController(requestId: requestId));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            '리뷰 작성',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Text(
                '청소 서비스는 만족하셨나요?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              // 소통
              _buildRatingRow('소통', controller.communicationRating),
              SizedBox(height: 16),
              
              // 청소 완성도
              _buildRatingRow('청소 완성도', controller.qualityRating),
              SizedBox(height: 16),
              
              // 일정 신뢰도
              _buildRatingRow('일정 신뢰도', controller.reliabilityRating),
              SizedBox(height: 16),
              
              // 가격
              _buildRatingRow('가격', controller.priceRating),
              SizedBox(height: 24),
              
              Divider(),
              SizedBox(height: 16),

              Text(
                '총 평점',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Obx(() => Text(
                '${controller.totalRating}점',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              )),
              SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '상세 후기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: controller.commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '서비스 이용 경험을 솔직하게 작성해주세요.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E88E5),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          '리뷰 등록하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, RxDouble ratingObx) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        Obx(() => RatingBar.builder(
          initialRating: ratingObx.value,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder: (context, _) => Icon(
            Icons.star,
            color: Colors.amber,
          ),
          onRatingUpdate: (rating) {
            ratingObx.value = rating;
          },
        )),
      ],
    );
  }
}
