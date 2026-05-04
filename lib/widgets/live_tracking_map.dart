import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/live_tracking_service.dart';

class LiveTrackingMap extends StatefulWidget {
  final String trackingId;
  final bool isDriver;
  final LatLng? userLocation;
  final LatLng? serviceCenterLocation;

  const LiveTrackingMap({
    super.key,
    required this.trackingId,
    this.isDriver = false,
    this.userLocation,
    this.serviceCenterLocation,
  });

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  final LiveTrackingService _trackingService = LiveTrackingService();
  final MapController _mapController = MapController();

  LatLng? _currentLocation;
  StreamSubscription? _locationSubscription;
  bool _isLoading = true;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  Future<void> _initTracking() async {
    final hasPermission = await _trackingService.requestPermission();
    if (!mounted) return;

    setState(() {
      _permissionGranted = hasPermission;
    });

    if (!hasPermission) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (widget.isDriver) {
      // For the driver/admin: Watch hardware location, update map and sync to Firebase
      _locationSubscription = _trackingService
          .getCurrentLocationStream()
          .listen((position) {
            final newLoc = LatLng(position.latitude, position.longitude);
            _trackingService.updateDriverLocation(widget.trackingId, newLoc);

            setState(() {
              _currentLocation = newLoc;
              _isLoading = false;
            });

            _mapController.move(
              newLoc,
              _mapController.camera.zoom > 5
                  ? _mapController.camera.zoom
                  : 15.0,
            );
          });
    } else {
      // For the user: Listen to the Firebase document to show driver location
      _locationSubscription = _trackingService
          .getDriverLocationStream(widget.trackingId)
          .listen((location) {
            if (location != null) {
              setState(() {
                _currentLocation = location;
                _isLoading = false;
              });

              _mapController.move(
                location,
                _mapController.camera.zoom > 5
                    ? _mapController.camera.zoom
                    : 15.0,
              );
            } else if (_currentLocation == null) {
              // If no location exists in DB yet
              setState(() {
                _isLoading = false;
              });
            }
          });
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Acquiring Location...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (!_permissionGranted) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 48, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'Location permission is required\nfor live tracking.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.userLocation ?? _currentLocation ?? widget.serviceCenterLocation ?? const LatLng(0, 0),
        initialZoom: (_currentLocation == null && widget.userLocation == null) ? 2.0 : 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.gearup',
        ),
        MarkerLayer(
          markers: [
            if (_currentLocation != null)
              Marker(
                point: _currentLocation!,
                width: 60,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.navigation,
                      color: Colors.redAccent,
                      size: 32,
                    ),
                  ),
                ),
              ),
            if (widget.userLocation != null)
              Marker(
                point: widget.userLocation!,
                width: 60,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_pin_circle,
                      color: Colors.blueAccent,
                      size: 32,
                    ),
                  ),
                ),
              ),
            if (widget.serviceCenterLocation != null)
              Marker(
                point: widget.serviceCenterLocation!,
                width: 60,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.store,
                      color: Colors.green,
                      size: 32,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
