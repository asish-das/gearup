import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  vehicleOwner('Vehicle Owner'),
  serviceCenter('Service Center'),
  admin('Admin'),
  superAdmin('Super Admin');

  const UserRole(this.displayName);
  final String displayName;

  static UserRole fromString(String? value) {
    if (value == null) return UserRole.vehicleOwner;
    return UserRole.values.firstWhere(
      (role) => role.name == value || role.displayName == value,
      orElse: () {
        debugPrint('Unknown role: $value');
        return UserRole.vehicleOwner;
      },
    );
  }
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
  final String? description;
  final double? rating;
  final int? reviewsCount;
  final Map<String, bool>? serviceCategories;
  final Map<String, String>? serviceCategoryDescriptions;

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
    this.description,
    this.rating,
    this.reviewsCount,
    this.serviceCategories,
    this.serviceCategoryDescriptions,
  });

  static String? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Timestamp) return value.toDate().toIso8601String();
    return value.toString();
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.fromString(map['role']),
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      businessName: map['businessName'],
      status: map['status'],
      createdAt: _parseDate(map['createdAt']),
      address: map['address'],
      description: map['description'],
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      reviewsCount: map['reviewsCount'] != null ? (map['reviewsCount'] as num).toInt() : null,
      serviceCategories: map['serviceCategories'] != null ? Map<String, bool>.from(map['serviceCategories']) : null,
      serviceCategoryDescriptions: map['serviceCategoryDescriptions'] != null ? Map<String, String>.from(map['serviceCategoryDescriptions']) : null,
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
      'description': description,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'serviceCategories': serviceCategories,
      'serviceCategoryDescriptions': serviceCategoryDescriptions,
    };
  }
}
