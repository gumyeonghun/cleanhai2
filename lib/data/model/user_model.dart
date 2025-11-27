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

  UserModel({
    required this.id,
    required this.email,
    this.address,
    this.latitude,
    this.longitude,
    this.userName,
    this.phoneNumber,
    this.profileImageUrl,
    this.userType = 'owner', // Default to owner for backward compatibility
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
    };
  }
}
