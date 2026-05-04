import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
        title: const Text(
          'Emergency Assistance',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.redAccent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Are you safe?',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'If you are in immediate danger or need medical help, please call 911 directly.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'What do you need?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildEmergencyOption(
              context,
              title: 'Tow Truck Request',
              description: 'Flatbed, wheel-lift, and heavy-duty towing options',
              icon: Icons.rv_hookup,
              color: Colors.orange,
              onTap: () => _showTowOptions(context),
            ),
            const SizedBox(height: 12),
            _buildEmergencyOption(
              context,
              title: 'Emergency Mobile Service',
              description: 'On-site mechanic for urgent repairs',
              icon: Icons.build_circle,
              color: Colors.blueAccent,
              onTap: () => _showDispatchDialog(context, 'Mobile Service Unit'),
            ),
            const SizedBox(height: 12),
            _buildEmergencyOption(
              context,
              title: 'Fuel Delivery',
              description: 'Run out of gas? We will bring fuel to you',
              icon: Icons.local_gas_station,
              color: Colors.green,
              onTap: () => _showDispatchDialog(context, 'Fuel Delivery Unit'),
            ),
            const SizedBox(height: 12),
            _buildEmergencyOption(
              context,
              title: 'Battery Jumpstart',
              description: 'Dead battery assistance',
              icon: Icons.battery_charging_full,
              color: Colors.amber,
              onTap: () => _showDispatchDialog(context, 'Jumpstart Service'),
            ),
            const SizedBox(height: 12),
            _buildEmergencyOption(
              context,
              title: 'Lockout Service',
              description: 'Locked your keys inside your vehicle?',
              icon: Icons.vpn_key,
              color: Colors.deepPurpleAccent,
              onTap: () => _showDispatchDialog(context, 'Locksmith Unit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  void _showTowOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Tow Vehicle Type',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTowOption(
                context,
                title: 'Flatbed Tow Truck',
                desc:
                    'Best for all-wheel drive, severe damage, or luxury vehicles.',
                icon: Icons.local_shipping,
              ),
              _buildTowOption(
                context,
                title: 'Wheel-Lift Tow Truck',
                desc: 'Good for standard 2-wheel drive and tight spaces.',
                icon: Icons.fire_truck,
              ),
              _buildTowOption(
                context,
                title: 'Heavy Duty Towing',
                desc: 'For large trucks, RVs, and commercial vehicles.',
                icon: Icons.airport_shuttle,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTowOption(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _showDispatchDialog(context, '$title Service');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDispatchDialog(BuildContext context, String serviceName) {
    showDialog(
      context: context,
      builder: (context) {
        String locationDescription = 'Fetching location...';
        bool isLocationFetching = true;
        Position? userPosition;
        String? selectedCenterId;
        String? selectedCenterName;
        bool findNearest = true;

        return StatefulBuilder(
          builder: (context, setState) {
            if (isLocationFetching) {
              _fetchCurrentAddressAndPosition().then((result) {
                if (context.mounted) {
                  setState(() {
                    locationDescription = result?['address'] ?? 'Current GPS Location';
                    userPosition = result?['position'];
                    isLocationFetching = false;
                  });
                }
              });
            }

            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: Text('Dispatch $serviceName?'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'A service vehicle will be dispatched to your current GPS location:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isLocationFetching) ...[
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ] else ...[
                            const Icon(
                              Icons.my_location,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                          ],
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationDescription,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Service Center',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => findNearest = !findNearest);
                          },
                          child: Text(
                            findNearest ? 'Show All' : 'Find Nearest',
                            style: const TextStyle(color: AppTheme.primary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('role', isEqualTo: 'serviceCenter')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          
                          var centers = snapshot.data!.docs.where((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return d['status'] == 'approved' || d['status'] == 'active';
                          }).toList();

                          if (centers.isEmpty) {
                            return const Center(child: Text("No centers available", style: TextStyle(color: Colors.white38)));
                          }

                          // If findNearest is true and none selected, pick the first one as default
                          if (selectedCenterId == null && centers.isNotEmpty) {
                            selectedCenterId = centers.first.id;
                            selectedCenterName = (centers.first.data() as Map<String, dynamic>)['businessName'] ?? 'Center';
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: centers.length,
                            itemBuilder: (context, index) {
                              final centerData = centers[index].data() as Map<String, dynamic>;
                              final cid = centers[index].id;
                              final cName = centerData['businessName'] ?? centerData['name'] ?? 'Center';
                              final isSelected = selectedCenterId == cid;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedCenterId = cid;
                                    selectedCenterName = cName;
                                    findNearest = false;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? AppTheme.primary : Colors.white12,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                                        color: isSelected ? AppTheme.primary : Colors.white24,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(cName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            Text(centerData['address'] ?? 'Nearby', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: selectedCenterId == null ? null : () async {
                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
                    );

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) throw "User not authenticated";

                      // Get user details
                      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                      final userData = userDoc.data() as Map<String, dynamic>;

                      final emergencyRef = FirebaseFirestore.instance.collection('emergencies').doc();
                      await emergencyRef.set({
                        'serviceType': serviceName,
                        'serviceCenterId': selectedCenterId,
                        'serviceCenterName': selectedCenterName,
                        'userId': user.uid,
                        'userName': userData['name'] ?? 'User',
                        'userPhone': userData['phoneNumber'] ?? user.phoneNumber ?? 'N/A',
                        'address': locationDescription,
                        if (userPosition != null)
                          'location': GeoPoint(userPosition!.latitude, userPosition!.longitude),
                        'timestamp': FieldValue.serverTimestamp(),
                        'status': 'PENDING',
                      });

                      if (context.mounted) {
                        Navigator.pop(context); // pop loading
                        Navigator.pop(context); // pop dispatch dialog
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Emergency assistance requested! Stay safe.')),
                        );

                        Navigator.pushNamed(
                          context,
                          '/tracking',
                          arguments: {
                            'isEmergency': true,
                            'serviceName': serviceName,
                            'trackingId': emergencyRef.id,
                          },
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // pop loading
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    }
                  },
                  child: const Text('Confirm Dispatch'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchCurrentAddressAndPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = '';
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        if (place.street != null && place.street!.isNotEmpty) {
          address += '${place.street}, ';
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += '${place.subLocality}, ';
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += place.locality!;
        }
      }

      return {
        'address': address.isNotEmpty ? address : null,
        'position': position,
      };
    } catch (e) {
      return null;
    }
  }
}
