import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicle {
  final String id;
  final String make;
  final String model;
  final String year;
  final String color;
  final String licensePlate;
  final String imageUrl;
  final int kilometers;
  final int lastServiceKm;
  final bool isConnected;
  final String userId;
  final String? createdAt;
  final String? updatedAt;

  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
    this.imageUrl = '',
    this.kilometers = 0,
    this.lastServiceKm = 0,
    this.isConnected = false,
    required this.userId,
    this.createdAt,
    this.updatedAt,
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Timestamp) return value.toDate().toIso8601String();
    return value.toString();
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? '',
      color: map['color'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      kilometers: _parseInt(map['kilometers']),
      lastServiceKm: _parseInt(map['lastServiceKm']),
      isConnected: map['isConnected'] ?? false,
      userId: map['userId'] ?? '',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'licensePlate': licensePlate,
      'imageUrl': imageUrl,
      'kilometers': kilometers,
      'lastServiceKm': lastServiceKm,
      'isConnected': isConnected,
      'userId': userId,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      'updatedAt': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  String get displayName => '$year $make $model';
  String get mileageDisplay => '$kilometers KM';
}
