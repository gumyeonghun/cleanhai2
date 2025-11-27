import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cleanhai2/data/model/progress_note.dart';
import 'package:cleanhai2/data/model/completion_report.dart';
import 'package:cleanhai2/data/model/review.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../report/widgets/completion_report_write_page.dart';
import '../../review/widgets/review_write_page.dart';
import '../cleaning_progress_controller.dart';

class CleaningProgressPage extends StatelessWidget {
  final String requestId;
  final bool isStaff;

  const CleaningProgressPage({
    super.key,
    required this.requestId,
    required this.isStaff,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CleaningProgressController(
      requestId: requestId,
      isStaff: isStaff,
    ));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '청소 진행 상황',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFFE53935)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        final request = controller.cleaningRequest.value;
        if (request == null) {
          return Center(child: Text('청소 정보를 찾을 수 없습니다.'));
        }

        return Column(
          children: [
            // 상단 상태 표시 카드
            _buildStatusCard(request.status, request.startedAt, request.completedAt, request.completionReport, request.review),
            
            // 진행 메모 리스트
            Expanded(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '진행 기록',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: request.progressNotes.isEmpty
                          ? Center(
                              child: Text(
                                '아직 기록된 진행 상황이 없습니다.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: request.progressNotes.length,
                              itemBuilder: (context, index) {
                                // 최신순으로 표시하기 위해 역순 접근
                                final note = request.progressNotes[request.progressNotes.length - 1 - index];
                                return _buildNoteItem(note);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 하단 액션 버튼
            _buildBottomActions(context, controller, request),
          ],
        );
      }),
    );
  }

  Widget _buildStatusCard(String status, DateTime? startedAt, DateTime? completedAt, CompletionReport? report, Review? review) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusText = '대기중';
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'in_progress':
        statusText = '청소중';
        statusColor = Colors.blue;
        statusIcon = Icons.cleaning_services;
        break;
      case 'completed':
        statusText = '완료됨';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusText = '알 수 없음';
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
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
        children: [
          Icon(statusIcon, size: 48, color: statusColor),
          SizedBox(height: 16),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          if (startedAt != null) ...[
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            _buildTimeRow('시작 시간', startedAt),
          ],
          if (completedAt != null) ...[
            SizedBox(height: 8),
            _buildTimeRow('완료 시간', completedAt),
          ],
          if (report != null) ...[
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Text('청소 완료 보고서가 제출되었습니다.', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ],
          if (review != null) ...[
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RatingBarIndicator(
                  rating: review.rating,
                  itemBuilder: (context, index) => Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 20.0,
                  direction: Axis.horizontal,
                ),
                SizedBox(width: 8),
                Text('${review.rating}점', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, DateTime time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(
          DateFormat('yyyy.MM.dd HH:mm').format(time),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildNoteItem(ProgressNote note) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.note,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            DateFormat('yyyy.MM.dd HH:mm').format(note.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, CleaningProgressController controller, dynamic request) {
    final status = request.status;
    final hasReport = request.completionReport != null;
    final hasReview = request.review != null;

    // 완료 상태이고 직원이 아니며 리뷰까지 작성했으면 버튼 숨김
    if (status == 'completed' && !isStaff && hasReview) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isStaff && status != 'completed') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddNoteDialog(context, controller),
                    icon: Icon(Icons.note_add),
                    label: Text('메모 추가'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Color(0xFFE53935),
                      side: BorderSide(color: Color(0xFFE53935)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
          ],
          
          if (isStaff) ...[
            if (status == 'pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.updateStatus('in_progress'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('청소 시작하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            else if (status == 'in_progress')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.updateStatus('completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('청소 완료하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            else if (status == 'completed')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => CompletionReportWritePage(requestId: request.id));
                  },
                  icon: Icon(Icons.assignment, color: Colors.white),
                  label: Text(hasReport ? '완료 보고서 수정' : '완료 보고서 작성', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE53935),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ] else ...[
            // 의뢰자 (고객)
             if (status == 'completed') ...[
               if (hasReport)
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton.icon(
                     onPressed: () {
                       // TODO: 보고서 보기 페이지로 이동 (현재는 작성 페이지 재활용하거나 별도 뷰어 필요)
                       // 일단 작성 페이지로 이동하되, 뷰어 모드가 필요함. 
                       // 간편하게 다이얼로그로 내용을 보여주거나, 
                       // CompletionReportViewPage를 만드는 것이 좋음.
                       // 여기서는 간단히 리뷰 작성으로 유도
                       if (!hasReview) {
                          Get.to(() => ReviewWritePage(requestId: request.id));
                       }
                     },
                     icon: Icon(Icons.rate_review, color: Colors.white),
                     label: Text(hasReview ? '리뷰 수정' : '리뷰 작성하기', 
                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Color(0xFFE53935),
                       padding: EdgeInsets.symmetric(vertical: 16),
                     ),
                   ),
                 )
               else
                 Text('청소 직원이 완료 보고서를 작성 중입니다.', style: TextStyle(color: Colors.grey)),
             ]
          ],
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, CleaningProgressController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('진행 메모 추가'),
        content: TextField(
          controller: controller.noteController,
          decoration: InputDecoration(
            hintText: '예: 거실 청소 완료, 쓰레기 분리수거 중...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: controller.addNote,
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE53935)),
            child: Text('추가', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
