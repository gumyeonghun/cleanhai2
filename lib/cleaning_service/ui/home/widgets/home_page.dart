import 'package:cleanhai2/cleaning_service/ui/write/widgets/write_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/model/cleaning_request.dart';
import '../../../data/model/cleaning_staff.dart';
import '../../../data/model/user_model.dart';
import '../../../data/repository/cleaning_repository.dart';
import '../../detail/widgets/detail_page.dart';
import '../../profile/widgets/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authentication3 = FirebaseAuth.instance;
  final CleaningRepository _repository = CleaningRepository();
  int index = 0;
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _authentication3.currentUser;
    if (user != null) {
      final userProfile = await _repository.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _userModel = userProfile;
        });
      }
    }
  }

  double? _calculateDistance(double? targetLat, double? targetLng) {
    if (_userModel?.latitude == null || _userModel?.longitude == null || targetLat == null || targetLng == null) {
      return null;
    }
    return Geolocator.distanceBetween(
      _userModel!.latitude!,
      _userModel!.longitude!,
      targetLat,
      targetLng,
    );
  }

  // 청소 의뢰 아이템 위젯
  Widget requestItem(CleaningRequest request) {
    final distance = _calculateDistance(request.latitude, request.longitude);

    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return DetailPage(cleaningRequest: request);
              }),
            );
          },
          child: Container(
            height: 130,
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
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                request.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (distance != null) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(0xFF2575FC).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on, size: 12, color: Color(0xFF2575FC)),
                                    SizedBox(width: 4),
                                    Text(
                                      '${(distance / 1000).toStringAsFixed(1)}km',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2575FC),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            request.content,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          DateFormat('yyyy.MM.dd HH:mm').format(request.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (request.imageUrl != null && request.imageUrl!.isNotEmpty)
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        request.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[100],
                            child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 청소 대기 아이템 위젯
  Widget staffItem(CleaningStaff staff) {
    final distance = _calculateDistance(staff.latitude, staff.longitude);

    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return DetailPage(cleaningStaff: staff);
              }),
            );
          },
          child: Container(
            height: 130,
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
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                staff.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (distance != null) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(0xFF2575FC).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on, size: 12, color: Color(0xFF2575FC)),
                                    SizedBox(width: 4),
                                    Text(
                                      '${(distance / 1000).toStringAsFixed(1)}km',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2575FC),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            staff.content,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          DateFormat('yyyy.MM.dd HH:mm').format(staff.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (staff.imageUrl != null && staff.imageUrl!.isNotEmpty)
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        staff.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[100],
                            child: Icon(Icons.person, color: Colors.grey[400]),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: Text(
          '청소5분대기조',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF2575FC).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return WritePage();
              }),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.edit),
        ),
      ),
      body: IndexedStack(
        index: index,
        children: [
          // 청소 의뢰 페이지
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 청소 의뢰',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<List<CleaningRequest>>(
                    stream: _repository.getCleaningRequests(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
 
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('오류 발생: ${snapshot.error}'),
                        );
                      }
 
                      final requests = snapshot.data ?? [];
                      
                      // 거리순 정렬
                      if (_userModel?.latitude != null && _userModel?.longitude != null) {
                        requests.sort((a, b) {
                          final distA = _calculateDistance(a.latitude, a.longitude);
                          final distB = _calculateDistance(b.latitude, b.longitude);
                          
                          if (distA == null) return 1;
                          if (distB == null) return -1;
                          return distA.compareTo(distB);
                        });
                      }
 
                      if (requests.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cleaning_services_outlined, size: 60, color: Colors.grey[300]),
                              SizedBox(height: 16),
                              Text(
                                '등록된 청소 의뢰가 없습니다',
                                style: TextStyle(color: Colors.grey[500], fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }
 
                      return ListView.separated(
                        itemCount: requests.length,
                        padding: EdgeInsets.only(bottom: 80), // FAB space
                        itemBuilder: (context, index) => requestItem(requests[index]),
                        separatorBuilder: (context, index) => SizedBox(height: 16),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // 청소 대기 페이지
          Container(
            color: Colors.grey[50],
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '청소 인원 대기',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<List<CleaningStaff>>(
                      stream: _repository.getCleaningStaffs(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
 
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('오류 발생: ${snapshot.error}'),
                          );
                        }
 
                        final staffs = snapshot.data ?? [];
                        
                        // 거리순 정렬
                        if (_userModel?.latitude != null && _userModel?.longitude != null) {
                          staffs.sort((a, b) {
                            final distA = _calculateDistance(a.latitude, a.longitude);
                            final distB = _calculateDistance(b.latitude, b.longitude);
                            
                            if (distA == null) return 1;
                            if (distB == null) return -1;
                            return distA.compareTo(distB);
                          });
                        }
 
                        if (staffs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_off_outlined, size: 60, color: Colors.grey[300]),
                                SizedBox(height: 16),
                                Text(
                                  '대기 중인 청소 인원이 없습니다',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }
 
                        return ListView.separated(
                          itemCount: staffs.length,
                          padding: EdgeInsets.only(bottom: 80),
                          itemBuilder: (context, index) => staffItem(staffs[index]),
                          separatorBuilder: (context, index) => SizedBox(height: 16),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 청소 일정 확인 페이지
          Container(
            color: Colors.grey[50],
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '내 청소 일정',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<List<CleaningRequest>>(
                      stream: _authentication3.currentUser != null
                          ? _repository.getMyAcceptedRequestsAsOwner(_authentication3.currentUser!.uid)
                          : Stream.value([]),
                      builder: (context, ownerSnapshot) {
                        return StreamBuilder<List<CleaningRequest>>(
                          stream: _authentication3.currentUser != null
                              ? _repository.getMyAppliedRequestsAsStaff(_authentication3.currentUser!.uid)
                              : Stream.value([]),
                          builder: (context, staffSnapshot) {
                            if (ownerSnapshot.connectionState == ConnectionState.waiting ||
                                staffSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (ownerSnapshot.hasError || staffSnapshot.hasError) {
                              return Center(
                                child: Text('오류 발생: ${ownerSnapshot.error ?? staffSnapshot.error}'),
                              );
                            }

                            final ownerRequests = ownerSnapshot.data ?? [];
                            final staffRequests = staffSnapshot.data ?? [];
                            
                            // Combine and sort by createdAt
                            final allRequests = [...ownerRequests, ...staffRequests];
                            allRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                            if (allRequests.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 60, color: Colors.grey[300]),
                                    SizedBox(height: 16),
                                    Text(
                                      '수락된 청소 일정이 없습니다',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              itemCount: allRequests.length,
                              padding: EdgeInsets.only(bottom: 80),
                              itemBuilder: (context, index) {
                                final request = allRequests[index];
                                final isOwner = request.authorId == _authentication3.currentUser?.uid;
                                
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) {
                                        return DetailPage(cleaningRequest: request);
                                      }),
                                    );
                                  },
                                  child: Container(
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
                                        // Role badge
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isOwner 
                                                  ? [Color(0xFF6A11CB), Color(0xFF2575FC)]
                                                  : [Color(0xFF11998E), Color(0xFF38EF7D)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              topRight: Radius.circular(16),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isOwner ? Icons.business_center : Icons.cleaning_services,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                isOwner ? '의뢰자' : '청소직원',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Spacer(),
                                              // Status badge - show different status for staff
                                              if (!isOwner) ...[
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.3),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        request.acceptedApplicantId == _authentication3.currentUser?.uid
                                                            ? Icons.check_circle
                                                            : Icons.schedule,
                                                        color: Colors.white,
                                                        size: 14,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        request.acceptedApplicantId == _authentication3.currentUser?.uid
                                                            ? '수락됨'
                                                            : '대기중',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ] else ...[
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.3),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.check_circle, color: Colors.white, size: 14),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        '수락됨',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        // Request content
                                        Container(
                                          height: 130,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        request.title,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.black87,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Expanded(
                                                        child: Text(
                                                          request.content,
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 2,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.grey[600],
                                                            height: 1.4,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            DateFormat('yyyy.MM.dd HH:mm').format(request.createdAt),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey[400],
                                                            ),
                                                          ),
                                                          if (request.price != null && request.price!.isNotEmpty) ...[
                                                            SizedBox(width: 12),
                                                            Icon(Icons.payments, size: 12, color: Color(0xFF2575FC)),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              '${NumberFormat('#,###').format(int.tryParse(request.price!) ?? 0)}원',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Color(0xFF2575FC),
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              if (request.imageUrl != null && request.imageUrl!.isNotEmpty)
                                                Container(
                                                  width: 130,
                                                  height: 130,
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.only(
                                                      bottomRight: Radius.circular(16),
                                                    ),
                                                    child: Image.network(
                                                      request.imageUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          color: Colors.grey[100],
                                                          child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              separatorBuilder: (context, index) => SizedBox(height: 16),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 프로필 페이지
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF2575FC),
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          iconSize: 26,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          currentIndex: index,
          elevation: 0,
          onTap: (value) {
            setState(() {
              index = value;
              // 탭 전환 시 프로필 정보 다시 로드 (주소 변경 반영)
              if (value == 0 || value == 1) {
                _loadUserProfile();
              }
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '청소의뢰',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: '청소대기',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: '내청소일정',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '프로필',
            ),
          ],
        ),
      ),
    );
  }
}
