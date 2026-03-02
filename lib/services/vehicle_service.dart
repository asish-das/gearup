import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gearup/models/vehicle.dart';

class VehicleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _vehiclesCollection = _firestore.collection(
    'vehicles',
  );

  // Add a new vehicle
  static Future<String> addVehicle(Vehicle vehicle) async {
    try {
      String id = vehicle.id;
      if (id.isEmpty) {
        id = _vehiclesCollection.doc().id;
      }
      final data = vehicle.toMap();
      data['id'] = id;
      await _vehiclesCollection.doc(id).set(data);
      return id;
    } catch (e) {
      throw Exception('Failed to add vehicle: $e');
    }
  }

  // Get all vehicles for a user
  static Future<List<Vehicle>> getUserVehicles(String userId) async {
    try {
      final snapshot = await _vehiclesCollection
          .where('userId', isEqualTo: userId)
          .get();

      // Sort manually to avoid index requirement
      final vehicles = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Vehicle.fromMap(data);
      }).toList();

      // Sort by createdAt descending
      vehicles.sort((a, b) {
        final aTime =
            DateTime.tryParse(a.toMap()['createdAt'] ?? '') ?? DateTime.now();
        final bTime =
            DateTime.tryParse(b.toMap()['createdAt'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      return vehicles;
    } catch (e) {
      throw Exception('Failed to get vehicles: $e');
    }
  }

  // Get a specific vehicle
  static Future<Vehicle?> getVehicle(String vehicleId) async {
    try {
      final doc = await _vehiclesCollection.doc(vehicleId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Vehicle.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get vehicle: $e');
    }
  }

  // Update vehicle
  static Future<void> updateVehicle(
    String vehicleId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _vehiclesCollection.doc(vehicleId).update({
        ...data,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update vehicle: $e');
    }
  }

  // Update battery level
  static Future<void> updateBatteryLevel(
    String vehicleId,
    double batteryLevel,
  ) async {
    try {
      await _vehiclesCollection.doc(vehicleId).update({
        'batteryLevel': batteryLevel,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update battery level: $e');
    }
  }

  // Update connection status
  static Future<void> updateConnectionStatus(
    String vehicleId,
    bool isConnected,
  ) async {
    try {
      await _vehiclesCollection.doc(vehicleId).update({
        'isConnected': isConnected,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update connection status: $e');
    }
  }

  // Delete vehicle
  static Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _vehiclesCollection.doc(vehicleId).delete();
    } catch (e) {
      throw Exception('Failed to delete vehicle: $e');
    }
  }

  // Stream of user vehicles for real-time updates
  static Stream<List<Vehicle>> streamUserVehicles(String userId) {
    return _vehiclesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final vehicles = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Vehicle.fromMap(data);
          }).toList();

          // Sort manually to avoid index requirement
          vehicles.sort((a, b) {
            final aTime =
                DateTime.tryParse(a.toMap()['createdAt'] ?? '') ??
                DateTime.now();
            final bTime =
                DateTime.tryParse(b.toMap()['createdAt'] ?? '') ??
                DateTime.now();
            return bTime.compareTo(aTime);
          });

          return vehicles;
        });
  }
}
