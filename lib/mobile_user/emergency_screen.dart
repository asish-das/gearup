import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/live_tracking_service.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.redAccent.withOpacity(0.1),
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
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
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
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
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
        bool isFetching = true;

        return StatefulBuilder(
          builder: (context, setState) {
            if (isFetching) {
              _fetchCurrentAddress().then((address) {
                if (context.mounted) {
                  setState(() {
                    locationDescription = address ?? 'Current GPS Location';
                    isFetching = false;
                  });
                }
              });
            }

            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: Text('Dispatch $serviceName?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A service vehicle will be dispatched to your current GPS location:',
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isFetching) ...[
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.redAccent,
                        ),
                      ),
                    );

                    try {
                      final trackingService = LiveTrackingService();
                      String? trackingId = await trackingService
                          .createEmergencyRequest(serviceName);

                      if (context.mounted) {
                        Navigator.pop(context); // pop loading dialog
                        Navigator.pop(context); // pop dispatch dialog
                        Navigator.pushNamed(
                          context,
                          '/tracking',
                          arguments: {
                            'isEmergency': true,
                            'serviceName': serviceName,
                            'trackingId': trackingId,
                          },
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // pop loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Dispatch failed: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Confirm Emergency Dispatch'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _fetchCurrentAddress() async {
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

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = '';
        if (place.street != null && place.street!.isNotEmpty) {
          address += '${place.street}, ';
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += '${place.subLocality}, ';
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += place.locality!;
        }

        return address.isNotEmpty ? address : null;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
