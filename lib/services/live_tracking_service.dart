import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LiveTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize and get permissions
  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  // Admin/Service vehicle updates location to Firebase
  Future<void> updateDriverLocation(String trackingId, LatLng location) async {
    await _firestore.collection('trackings').doc(trackingId).set({
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Stream to get live driver location for the user view
  Stream<LatLng?> getDriverLocationStream(String trackingId) {
    return _firestore.collection('trackings').doc(trackingId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          return LatLng(data['latitude'], data['longitude']);
        }
      }
      return null;
    });
  }

  // Stream current hardware device location
  Stream<Position> getCurrentLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // update every 10 meters
      ),
    );
  }

  // Create an Emergency Request and return the document ID (trackingId)
  Future<String?> createEmergencyRequest(String serviceName) async {
    bool hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final docRef = await _firestore.collection('emergencies').add({
        'serviceName': serviceName,
        'status': 'dispatched',
        'user_latitude': position.latitude,
        'user_longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Initialize driver location marker at user's location initially
      await updateDriverLocation(
        docRef.id,
        LatLng(position.latitude, position.longitude),
      );

      return docRef.id;
    } catch (e) {
      return null;
    }
  }
}
