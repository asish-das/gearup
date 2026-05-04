import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final MapController _mapController = MapController();
  LatLng _currentLocation = const LatLng(10.8505, 76.2711); // Default to Kerala, India or somewhere generic
  bool _isLoadingLocation = true;
  List<DocumentSnapshot> _serviceCenters = [];

  @override
  void initState() {
    super.initState();
    _initLocationAndData();
  }

  Future<void> _initLocationAndData() async {
    await _getCurrentLocation();
    _fetchServiceCenters();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
      
      _mapController.move(_currentLocation, 13.0);
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  void _fetchServiceCenters() {
    FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'serviceCenter')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        final validCenters = snapshot.docs.where((doc) {
          final data = doc.data();
          final status = data['status']?.toString().toLowerCase();
          return status == 'approved' || status == 'active' || status == 'pending';
        }).toList();

        setState(() {
          _serviceCenters = validCenters;
        });
      }
    }, onError: (e) {
      debugPrint('Error fetching real-time updates: $e');
    });
  }

  ImageProvider? _getProfileImageProvider(String? source) {
    if (source == null || source.isEmpty) return null;
    if (source.startsWith('data:image')) {
      try {
        final base64Str = source.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (e) {
        return null;
      }
    }
    return CachedNetworkImageProvider(source);
  }

  // A helper to generate dummy coordinates for centers that don't have them in the DB
  // This is just for demonstration if real coordinates are missing.
  LatLng _getCenterLocation(Map<String, dynamic> data, int index) {
    final lat = data['latitude'];
    final lng = data['longitude'];

    if (lat != null && lng != null) {
      try {
        double? latVal;
        double? lngVal;
        
        if (lat is num) {
          latVal = lat.toDouble();
        } else if (lat is String) {
          latVal = double.tryParse(lat);
        }
        
        if (lng is num) {
          lngVal = lng.toDouble();
        } else if (lng is String) {
          lngVal = double.tryParse(lng);
        }

        if (latVal != null && lngVal != null) {
          return LatLng(latVal, lngVal);
        }
      } catch (e) {
        debugPrint('Error parsing coordinates for center: $e');
      }
    }
    
    // Create a slight offset from current location based on index
    double offsetLat = (index % 5) * 0.01 - 0.02;
    double offsetLng = (index ~/ 5) * 0.01 - 0.02;
    return LatLng(_currentLocation.latitude + offsetLat, _currentLocation.longitude + offsetLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        title: const Text(
          'Nearby Service Centers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.gearup',
                    ),
                    MarkerLayer(
                      markers: [
                        // User location marker
                        Marker(
                          point: _currentLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                        // Service centers markers
                        ..._serviceCenters.asMap().entries.map((entry) {
                          int idx = entry.key;
                          final docData = entry.value.data();
                          if (docData == null || docData is! Map<String, dynamic>) {
                            return const Marker(point: LatLng(0, 0), child: SizedBox());
                          }
                          final data = docData;
                          final point = _getCenterLocation(data, idx);
                          
                          return Marker(
                            point: point,
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () {
                                _showCenterDetails(context, entry.value);
                              },
                              child: const Icon(
                                Icons.location_on,
                                color: AppTheme.accent,
                                size: 40,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
                
                // Bottom sheet with list of centers
                DraggableScrollableSheet(
                  initialChildSize: 0.3,
                  minChildSize: 0.1,
                  maxChildSize: 0.6,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.95),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Drag handle
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white38,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Expanded(
                            child: _serviceCenters.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No service centers found nearby',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _initLocationAndData,
                                    color: AppTheme.primary,
                                    backgroundColor: AppTheme.surface,
                                    child: ListView.builder(
                                        controller: scrollController,
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        itemCount: _serviceCenters.length,
                                        itemBuilder: (context, index) {
                                      final doc = _serviceCenters[index];
                                      final docData = doc.data();
                                      if (docData == null || docData is! Map<String, dynamic>) {
                                        return const SizedBox.shrink();
                                      }
                                      final data = docData;
                                      final name = data['businessName'] ?? data['name'] ?? 'Service Center';
                                      final rating = data['rating']?.toString() ?? 'New';
                                      
                                      return Card(
                                        color: AppTheme.backgroundDark.withValues(alpha: 0.5),
                                        margin: const EdgeInsets.only(bottom: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(12),
                                          leading: CircleAvatar(
                                            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                                            backgroundImage: _getProfileImageProvider(data['profileImageUrl']?.toString()),
                                            child: _getProfileImageProvider(data['profileImageUrl']?.toString()) == null
                                                ? const Icon(Icons.store, color: AppTheme.primary)
                                                : null,
                                          ),
                                          title: Text(
                                            name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            (data['serviceCategories'] is Map)
                                                ? (data['serviceCategories'] as Map<String, dynamic>)
                                                    .entries
                                                    .where((e) => e.value == true)
                                                    .map((e) => e.key)
                                                    .join(', ')
                                                : 'No services listed',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                rating,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            final loc = _getCenterLocation(data, index);
                                            _mapController.move(loc, 15.0);
                                            _showCenterDetails(context, doc);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                  },
                ),
              ],
            ),
    );
  }

  void _showCenterDetails(BuildContext context, DocumentSnapshot doc) {
    final docData = doc.data();
    if (docData == null || docData is! Map<String, dynamic>) return;
    final data = docData;
    final name = data['businessName'] ?? data['name'] ?? 'Service Center';
    final imageProvider = _getProfileImageProvider(data['profileImageUrl']?.toString());
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    image: imageProvider != null
                        ? DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageProvider == null
                      ? const Icon(Icons.store, color: AppTheme.primary, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              data['rating']?.toString() ?? 'New',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Services Highlight Section
            if (data['serviceCategories'] != null) ...[
              const Text(
                'Services Provided',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (data['serviceCategories'] as Map<String, dynamic>)
                    .entries
                    .where((e) => e.value == true)
                    .map((e) {
                  final catName = e.key;
                  final catDesc = (data['serviceCategoryDescriptions'] is Map) 
                      ? data['serviceCategoryDescriptions'][catName]?.toString() ?? ''
                      : '';
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: AppTheme.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                catName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (catDesc.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  catDesc,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            // General Description
            Text(
              data['description'] ?? 'Professional vehicle maintenance and repair services.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pushNamed(
                    context,
                    '/service_selection',
                    arguments: {
                      'serviceCenterId': doc.id,
                      'serviceCenterName': name,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Book Service Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
