import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kpostal/kpostal.dart';
import 'package:geocoding/geocoding.dart';
import '../../../data/model/cleaning_request.dart';
import '../../../data/model/cleaning_staff.dart';
import '../../../data/repository/cleaning_repository.dart';

class WritePage extends StatefulWidget {
  final String? type; // 'request' or 'staff'
  final CleaningRequest? existingRequest;
  final CleaningStaff? existingStaff;

  const WritePage({
    super.key,
    this.type,
    this.existingRequest,
    this.existingStaff,
  });

  @override
  State<WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<WritePage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final CleaningRepository _repository = CleaningRepository();
  final ImagePicker _picker = ImagePicker();

  String _selectedType = 'request'; // 'request' or 'staff'
  File? _imageFile;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _isEditMode = false;

  String? _address;
  double? _latitude;
  double? _longitude;
  String? _userType; // 'owner' or 'staff'

  @override
  void initState() {
    super.initState();
    
    // 타입 설정
    if (widget.type != null) {
      _selectedType = widget.type!;
    }

    // 수정 모드 확인 및 데이터 로드
    if (widget.existingRequest != null) {
      _isEditMode = true;
      _selectedType = 'request';
      titleController.text = widget.existingRequest!.title;
      contentController.text = widget.existingRequest!.content;
      priceController.text = widget.existingRequest!.price ?? '';
      _existingImageUrl = widget.existingRequest!.imageUrl;
      _address = widget.existingRequest!.address;
      _latitude = widget.existingRequest!.latitude;
      _longitude = widget.existingRequest!.longitude;
    } else if (widget.existingStaff != null) {
      _isEditMode = true;
      _selectedType = 'staff';
      titleController.text = widget.existingStaff!.title;
      contentController.text = widget.existingStaff!.content;
      _existingImageUrl = widget.existingStaff!.imageUrl;
      _address = widget.existingStaff!.address;
      _latitude = widget.existingStaff!.latitude;
      _longitude = widget.existingStaff!.longitude;
    }
    
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userProfile = await _repository.getUserProfile(user.uid);
      if (mounted && userProfile != null) {
        setState(() {
          _userType = userProfile.userType;
          // Set default type based on user role if not in edit mode
          if (!_isEditMode) {
            if (_userType == 'owner') {
              _selectedType = 'request';
            } else if (_userType == 'staff') {
              _selectedType = 'staff';
            }
          }
        });
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 실패: $e')),
        );
      }
    }
  }

  Future<void> _searchAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KpostalView(
          callback: (Kpostal result) async {
            double? lat = result.latitude;
            double? lng = result.longitude;

            // 좌표가 없는 경우 주소로 좌표 검색
            if (lat == null || lng == null) {
              try {
                List<Location> locations = await locationFromAddress(result.address);
                if (locations.isNotEmpty) {
                  lat = locations.first.latitude;
                  lng = locations.first.longitude;
                }
              } catch (e) {
                debugPrint('좌표 변환 실패: $e');
              }
            }

            setState(() {
              _address = result.address;
              _latitude = lat;
              _longitude = lng;
            });
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다');
      }

      String? imageUrl = _existingImageUrl;

      // 새 이미지가 선택된 경우 업로드
      if (_imageFile != null) {
        imageUrl = await _repository.uploadImage(_imageFile!, _selectedType);
        
        // 기존 이미지가 있었다면 삭제
        if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
          await _repository.deleteImage(_existingImageUrl!);
        }
      }

      final now = DateTime.now();

      if (_selectedType == 'request') {
        if (_isEditMode && widget.existingRequest != null) {
          // 청소 의뢰 수정
          final updatedRequest = widget.existingRequest!.copyWith(
            title: titleController.text.trim(),
            content: contentController.text.trim(),
            price: priceController.text.trim(),
            imageUrl: imageUrl,
            address: _address,
            latitude: _latitude,
            longitude: _longitude,
            updatedAt: now,
          );
          await _repository.updateCleaningRequest(updatedRequest);
        } else {
          // 청소 의뢰 생성
          final request = CleaningRequest(
            id: '',
            authorId: user.uid,
            authorName: user.email ?? '익명',
            title: titleController.text.trim(),
            content: contentController.text.trim(),
            price: priceController.text.trim(),
            imageUrl: imageUrl,
            address: _address,
            latitude: _latitude,
            longitude: _longitude,
            createdAt: now,
            updatedAt: now,
          );
          await _repository.createCleaningRequest(request);
        }
      } else {
        if (_isEditMode && widget.existingStaff != null) {
          // 청소 대기 수정
          final updatedStaff = widget.existingStaff!.copyWith(
            title: titleController.text.trim(),
            content: contentController.text.trim(),
            imageUrl: imageUrl,
            address: _address,
            latitude: _latitude,
            longitude: _longitude,
            updatedAt: now,
          );
          await _repository.updateCleaningStaff(updatedStaff);
        } else {
          // 청소 대기 생성
          final staff = CleaningStaff(
            id: '',
            authorId: user.uid,
            authorName: user.email ?? '익명',
            title: titleController.text.trim(),
            content: contentController.text.trim(),
            imageUrl: imageUrl,
            address: _address,
            latitude: _latitude,
            longitude: _longitude,
            createdAt: now,
            updatedAt: now,
          );
          await _repository.createCleaningStaff(staff);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? '수정되었습니다' : '등록되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            _isEditMode ? '수정하기' : '글쓰기',
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
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            GestureDetector(
              onTap: _isLoading ? null : _submit,
              child: Container(
                margin: EdgeInsets.only(right: 16),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        '완료',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: Form(
          key: formKey,
          child: ListView(
            padding: EdgeInsets.all(24),
            children: [
              // 타입 선택 (수정 모드가 아닐 때만)
              // Only show type selection if userType is not loaded yet or for some reason we want to allow it (maybe admin?)
              // For now, we hide it if userType is known.
              if (!_isEditMode && _userType == null)
                Container(
                  margin: EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = 'request';
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: _selectedType == 'request'
                                  ? Color(0xFF2575FC)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '청소 의뢰',
                              style: TextStyle(
                                color: _selectedType == 'request'
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = 'staff';
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: _selectedType == 'staff'
                                  ? Color(0xFF2575FC)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '청소 대기',
                              style: TextStyle(
                                color: _selectedType == 'staff'
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // 제목
              Text(
                '제목',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: _selectedType == 'request' ? '예: 롯데호텔입니다' : '예: 20년차 가정주부입니다',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF2575FC)),
                  ),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return '제목을 입력해 주세요';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 24),

              // 금액 (청소 의뢰일 때만)
              if (_selectedType == 'request') ...[
                Text(
                  '청소 금액',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: '예: 50000',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF2575FC)),
                    ),
                    suffixText: '원',
                  ),
                  validator: (value) {
                    if (_selectedType == 'request' && (value?.trim().isEmpty ?? true)) {
                      return '금액을 입력해 주세요';
                    }
                    return null;
                  },
                ),
              ],
              
              SizedBox(height: 24),

              // 내용
              Text(
                '내용',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: TextFormField(
                  controller: contentController,
                  maxLines: null,
                  expands: true,
                  textInputAction: TextInputAction.newline,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: _selectedType == 'request'
                        ? '예: 5시부터 3개호실 청소 부탁드립니다'
                        : '예: 어떤 청소든지 자신있습니다',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF2575FC)),
                    ),
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return '내용을 입력해 주세요';
                    }
                    return null;
                  },
                ),
              ),
              
              SizedBox(height: 24),

              // 주소 선택
              Text(
                '위치',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _searchAddress,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: _address != null ? Color(0xFF2575FC) : Colors.grey[400]),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _address ?? '위치 추가 (선택사항)',
                          style: TextStyle(
                            color: _address != null ? Colors.black87 : Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // 이미지 선택
              Text(
                '사진',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _existingImageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[400]),
                                SizedBox(height: 12),
                                Text(
                                  '사진 추가하기',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
              
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
