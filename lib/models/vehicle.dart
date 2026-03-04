class Vehicle {
  final String id;
  final String make;
  final String model;
  final String year;
  final String color;
  final String licensePlate;
  final String imageUrl;
  final double batteryLevel;
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
    this.batteryLevel = 0.0,
    this.isConnected = false,
    required this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? '',
      color: map['color'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      batteryLevel: (map['batteryLevel'] ?? 0.0).toDouble(),
      isConnected: map['isConnected'] ?? false,
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
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
      'batteryLevel': batteryLevel,
      'isConnected': isConnected,
      'userId': userId,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      'updatedAt': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  String get displayName => '$year $make $model';
  String get batteryDisplay => '${batteryLevel.toInt()}% Charge';
}
