import 'package:cleanhai2/chatting/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../data/model/cleaning_request.dart';
import '../../../data/model/cleaning_staff.dart';
import '../../../data/model/user_model.dart';
import '../../../data/repository/cleaning_repository.dart';
import '../../../services/toss_payment_service.dart';
import '../../write/widgets/write_page.dart';
import 'package:uuid/uuid.dart';
import 'package:cleanhai2/cleaning_service/ui/payment/payment_selection_page.dart';

class DetailPage extends StatefulWidget {
  final CleaningRequest? cleaningRequest;
  final CleaningStaff? cleaningStaff;

  const DetailPage({
    super.key,
    this.cleaningRequest,
    this.cleaningStaff,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final CleaningRepository _repository = CleaningRepository();
  CleaningRequest? _currentRequest;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.cleaningRequest;
    if (widget.cleaningRequest != null) {
      _loadRequestData();
    }
  }

  Future<void> _loadRequestData() async {
    if (widget.cleaningRequest != null) {
      final updated = await _repository.getCleaningRequestById(widget.cleaningRequest!.id);
      if (mounted && updated != null) {
        setState(() {
          _currentRequest = updated;
        });
      }
    }
  }

  String get _title {
    if (_currentRequest != null) return _currentRequest!.title;
    if (widget.cleaningStaff != null) return widget.cleaningStaff!.title;
    return '';
  }

  String get _content {
    if (_currentRequest != null) return _currentRequest!.content;
    if (widget.cleaningStaff != null) return widget.cleaningStaff!.content;
    return '';
  }

  String get _authorName {
    if (_currentRequest != null) return _currentRequest!.authorName;
    if (widget.cleaningStaff != null) return widget.cleaningStaff!.authorName;
    return '';
  }

  String get _authorId {
    if (_currentRequest != null) return _currentRequest!.authorId;
    if (widget.cleaningStaff != null) return widget.cleaningStaff!.authorId;
    return '';
  }

  String? get _imageUrl {
    if (_currentRequest != null) return _currentRequest!.imageUrl;
    if (widget.cleaningStaff != null) return widget.cleaningStaff!.imageUrl;
    return null;
  }

  DateTime get _createdAt {
    if (_currentRequest != null) return _currentRequest!.createdAt;
    if (widget.cleaningStaff != null) return widget.cleaningStaff!.createdAt;
    return DateTime.now();
  }

  String? get _price {
    if (_currentRequest != null) return _currentRequest!.price;
    return null;
  }

  bool get _isAuthor {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == _authorId;
  }

  bool get _hasApplied {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _currentRequest == null) return false;
    return _currentRequest!.applicants.contains(currentUser.uid);
  }

  Future<void> _deleteItem(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('삭제 확인'),
        content: Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (_currentRequest != null) {
          await _repository.deleteCleaningRequest(_currentRequest!.id);
        } else if (widget.cleaningStaff != null) {
          await _repository.deleteCleaningStaff(widget.cleaningStaff!.id);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e')),
          );
        }
      }
    }
  }

  Future<void> _applyForJob() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    try {
      await _repository.applyForCleaning(_currentRequest!.id, user.uid);
      await _loadRequestData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('청소 신청이 완료되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('신청 실패: $e')),
        );
      }
    }
  }

  Future<void> _acceptApplicant(String applicantId, UserModel? applicantProfile) async {
    // Validate that price is set
    if (_price == null || _price!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('청소 금액이 설정되지 않았습니다')),
        );
      }
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 필요합니다')),
        );
      }
      return;
    }

    if (applicantProfile == null) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('신청자 정보를 불러올 수 없습니다')),
        );
      }
      return;
    }

    // Navigate to PaymentSelectionPage
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSelectionPage(
          applicant: applicantProfile,
          price: _price!,
          orderName: _title,
          orderId: Uuid().v4(),
          customerEmail: currentUser.email!,
        ),
      ),
    );

    // Handle payment result
    if (result != null && result['success'] == true) {
      try {
        // Show loading indicator for updating status
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(child: CircularProgressIndicator()),
          );
        }

        await _repository.acceptApplicant(
          _currentRequest!.id,
          applicantId,
          paymentKey: result['paymentKey'],
          orderId: result['orderId'],
        );

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('매칭이 완료되었습니다')),
          );
          _loadRequestData(); // Refresh data
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('매칭 처리 중 오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  void _showApplicantProfile(UserModel? userProfile, String applicantId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF2575FC),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '청소 직원 프로필',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          userProfile?.userType == 'staff' ? '청소 직원' : '숙박업소',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              Divider(),
              SizedBox(height: 16),
              
              // Profile details
              if (userProfile != null) ...[
                _buildProfileRow(
                  icon: Icons.email,
                  label: '이메일',
                  value: userProfile.email,
                ),
                SizedBox(height: 16),
                
                if (userProfile.address != null && userProfile.address!.isNotEmpty) ...[
                  _buildProfileRow(
                    icon: Icons.location_on,
                    label: '주소',
                    value: userProfile.address!,
                  ),
                  SizedBox(height: 16),
                ],
                
                if (userProfile.latitude != null && userProfile.longitude != null) ...[
                  _buildProfileRow(
                    icon: Icons.map,
                    label: '위치',
                    value: '위도: ${userProfile.latitude!.toStringAsFixed(4)}, 경도: ${userProfile.longitude!.toStringAsFixed(4)}',
                  ),
                  SizedBox(height: 16),
                ],
                
                _buildProfileRow(
                  icon: Icons.badge,
                  label: '회원 유형',
                  value: userProfile.userType == 'staff' ? '청소 직원' : '숙박업소',
                ),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '프로필 정보를 불러올 수 없습니다',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
              
              SizedBox(height: 24),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2575FC),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '닫기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Color(0xFF2575FC),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        actions: [
          Text(
            '대화하기',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          iconButton(Icons.message, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return ChatScreen();
              }),
            );
          }),
          if (_isAuthor) ...[
            iconButton(Icons.delete, () {
              _deleteItem(context);
            }),
            iconButton(Icons.edit, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return WritePage(
                    existingRequest: _currentRequest,
                    existingStaff: widget.cleaningStaff,
                  );
                }),
              );
            }),
          ],
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: 300),
        children: [
          if (_imageUrl != null && _imageUrl!.isNotEmpty)
            Image.network(
              _imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, size: 50),
                );
              },
            )
          else
            Container(
              height: 200,
              color: Colors.grey[300],
              child: Icon(Icons.image, size: 50, color: Colors.grey[600]),
            ),
          SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                SizedBox(height: 15),
                Text(
                  _authorName,
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(height: 5),
                Text(
                  DateFormat('yyyy.MM.dd HH:mm').format(_createdAt),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w200),
                ),
                
                // 청소 금액 표시 (청소 의뢰일 때만)
                if (_price != null && _price!.isNotEmpty) ...[
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF2575FC).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF2575FC).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.payments, color: Color(0xFF2575FC)),
                        SizedBox(width: 12),
                        Text(
                          '청소 금액: ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${NumberFormat('#,###').format(int.tryParse(_price!) ?? 0)}원',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2575FC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: 15),
                Text(
                  _content,
                  style: TextStyle(fontSize: 15),
                ),
                
                // 청소 신청 버튼 (청소 의뢰이고, 작성자가 아닐 때)
                if (_currentRequest != null && !_isAuthor && currentUser != null) ...[
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasApplied ? null : _applyForJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasApplied ? Colors.grey : Color(0xFF2575FC),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _hasApplied ? '신청 완료' : '청소 신청하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
                
                // 신청자 목록 (작성자일 때만)
                if (_currentRequest != null && _isAuthor && _currentRequest!.applicants.isNotEmpty) ...[
                  SizedBox(height: 24),
                  Text(
                    '신청자 목록',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 12),
                  ...(_currentRequest!.applicants.map((applicantId) {
                    final isAccepted = _currentRequest!.acceptedApplicantId == applicantId;
                    
                    return FutureBuilder<UserModel?>(
                      future: _repository.getUserProfile(applicantId),
                      builder: (context, snapshot) {
                        final userProfile = snapshot.data;
                        final displayName = userProfile?.email ?? applicantId;
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAccepted ? Color(0xFF2575FC).withValues(alpha: 0.1) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isAccepted ? Color(0xFF2575FC) : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showApplicantProfile(userProfile, applicantId),
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    children: [
                                      // Profile icon (no photo in UserModel)
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isAccepted ? Color(0xFF2575FC) : Colors.grey[400],
                                        child: Icon(
                                          isAccepted ? Icons.check_circle : Icons.person,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    displayName,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: isAccepted ? FontWeight.bold : FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.info_outline,
                                                  size: 16,
                                                  color: Colors.grey[500],
                                                ),
                                              ],
                                            ),
                                            if (userProfile?.address != null && userProfile!.address!.isNotEmpty) ...[
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                                                  SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      userProfile.address!,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              if (!isAccepted)
                                ElevatedButton(
                                  onPressed: () => _acceptApplicant(applicantId, userProfile),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF2575FC),
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    '수락',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              else
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF2575FC),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '수락됨',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget iconButton(IconData icon, void Function() onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        color: Colors.transparent,
        child: Icon(icon),
      ),
    );
  }
}
