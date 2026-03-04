import 'package:flutter/foundation.dart';

enum UserRole {
  vehicleOwner('Vehicle Owner'),
  serviceCenter('Service Center'),
  admin('Admin');

  const UserRole(this.displayName);
  final String displayName;
}

class User {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? businessName;
  final String? status;
  final String? createdAt;
  final String? address;

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
    this.businessName,
    this.status,
    this.createdAt,
    this.address,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == map['role'],
        orElse: () {
          debugPrint('Unknown role: ${map['role']}');
          return UserRole.vehicleOwner;
        },
      ),
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      businessName: map['businessName'],
      status: map['status'],
      createdAt: map['createdAt'],
      address: map['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.name,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'businessName': businessName,
      'status': status,
      'createdAt': createdAt,
      'address': address,
    };
  }
}
