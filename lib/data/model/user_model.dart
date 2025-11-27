import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? userName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String userType; // 'owner' or 'staff'

  final List<String>? availableDays;
  final String? availableStartTime;
  final String? availableEndTime;
  final bool isAutoRegisterEnabled;
  final String? cleaningDetails; // For owners: Room info, etc.
  final DateTime? birthDate;

  UserModel({
    required this.id,
    required this.email,
    this.address,
    this.latitude,
    this.longitude,
    this.userName,
    this.phoneNumber,
    this.profileImageUrl,
    this.userType = 'owner',
    this.availableDays,
    this.availableStartTime,
    this.availableEndTime,
    this.isAutoRegisterEnabled = false,
    this.cleaningDetails,
    this.birthDate,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      address: data['address'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      userName: data['userName'],
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      userType: data['userType'] ?? 'owner',
      availableDays: List<String>.from(data['availableDays'] ?? []),
      availableStartTime: data['availableStartTime'],
      availableEndTime: data['availableEndTime'],
      isAutoRegisterEnabled: data['isAutoRegisterEnabled'] ?? false,
      cleaningDetails: data['cleaningDetails'],
      birthDate: data['birthDate'] != null ? (data['birthDate'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'userName': userName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'userType': userType,
      'availableDays': availableDays,
      'availableStartTime': availableStartTime,
      'availableEndTime': availableEndTime,
      'isAutoRegisterEnabled': isAutoRegisterEnabled,
      'cleaningDetails': cleaningDetails,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
    };
  }
}
