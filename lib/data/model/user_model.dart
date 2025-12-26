import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? address;
  final String? detailAddress;
  // latitude, longitude removed
  final String? userName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String userType; // 'owner' or 'staff'

  final List<String>? availableDays;
  final String? availableStartTime;
  final String? availableEndTime;
  final bool isAutoRegisterEnabled;
  final String? cleaningDetails; // For owners: Room info, etc.
  final String? preferredCleaningType; // For owners: Preferred cleaning type
  final String? cleaningToolLocation; // For owners: Cleaning tool location
  final String? cleaningPrecautions; // For owners: Cleaning precautions
  final String? cleaningPrice; // For staff: Base cleaning price
  final String? additionalOptionCost; // For staff: Additional option costs
  final String? autoRegisterTitle; // For staff: Auto-register title
  final DateTime? birthDate;
  final String? cleaningRequestImageUrl; // For owners: Image for auto-registered requests
  
  // Soft delete fields
  final bool isDeleted;
  final DateTime? deletedAt;

  UserModel({
    required this.id,
    required this.email,
    this.address,
    this.detailAddress,
    // latitude, longitude removed
    this.userName,
    this.phoneNumber,
    this.profileImageUrl,
    this.userType = 'owner',
    this.availableDays,
    this.availableStartTime,
    this.availableEndTime,
    this.isAutoRegisterEnabled = false,
    this.cleaningDetails,
    this.preferredCleaningType,
    this.cleaningToolLocation,
    this.cleaningPrecautions,
    this.cleaningPrice,
    this.additionalOptionCost,
    this.autoRegisterTitle,
    this.birthDate,
    this.cleaningRequestImageUrl,
    this.isDeleted = false,
    this.deletedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      address: data['address'],
      detailAddress: data['detailAddress'],
      // latitude: data['latitude'], // Removed
      // longitude: data['longitude'], // Removed
      userName: data['userName'],
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      userType: data['userType'] ?? 'owner',
      availableDays: List<String>.from(data['availableDays'] ?? []),
      availableStartTime: data['availableStartTime'],
      availableEndTime: data['availableEndTime'],
      isAutoRegisterEnabled: data['isAutoRegisterEnabled'] ?? false,
      cleaningDetails: data['cleaningDetails'],
      preferredCleaningType: data['preferredCleaningType'],
      cleaningToolLocation: data['cleaningToolLocation'],
      cleaningPrecautions: data['cleaningPrecautions'],
      cleaningPrice: data['cleaningPrice'],
      additionalOptionCost: data['additionalOptionCost'],
      autoRegisterTitle: data['autoRegisterTitle'],
      birthDate: data['birthDate'] != null ? (data['birthDate'] as Timestamp).toDate() : null,
      cleaningRequestImageUrl: data['cleaningRequestImageUrl'],
      isDeleted: data['isDeleted'] ?? false,
      deletedAt: data['deletedAt'] != null ? (data['deletedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'address': address,
      'detailAddress': detailAddress,
      // 'latitude': latitude, // Removed
      // 'longitude': longitude, // Removed
      'userName': userName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'userType': userType,
      'availableDays': availableDays,
      'availableStartTime': availableStartTime,
      'availableEndTime': availableEndTime,
      'isAutoRegisterEnabled': isAutoRegisterEnabled,
      'cleaningDetails': cleaningDetails,
      'preferredCleaningType': preferredCleaningType,
      'cleaningToolLocation': cleaningToolLocation,
      'cleaningPrecautions': cleaningPrecautions,
      'cleaningPrice': cleaningPrice,
      'additionalOptionCost': additionalOptionCost,
      'autoRegisterTitle': autoRegisterTitle,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'cleaningRequestImageUrl': cleaningRequestImageUrl,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }
}
