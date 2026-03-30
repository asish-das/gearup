import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:gearup/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dashboard_view.dart';
import 'bookings_view.dart';
import 'customers_view.dart';
import 'revenue_view.dart';
import 'my_services_view.dart';
import 'profile_view.dart';
import 'service_inventory_view.dart';
import 'emergency_requests_view.dart';

class ServiceScaffold extends StatefulWidget {
  const ServiceScaffold({super.key});

  @override
  State<ServiceScaffold> createState() => _ServiceScaffoldState();
}

class _ServiceScaffoldState extends State<ServiceScaffold>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _emergencySubscription;
  int _pendingEmergencies = 0;
  late AnimationController _flashController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeInOut,
    );

    _setupStatusListener();
    _setupEmergencyListener();
  }

  void _setupEmergencyListener() {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emergencySubscription = FirebaseFirestore.instance
          .collection('emergencies')
          .where('serviceCenterId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'PENDING')
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _pendingEmergencies = snapshot.docs.length;
          });
          if (_pendingEmergencies > 0) {
            _flashController.repeat(reverse: true);
          } else {
            _flashController.stop();
            _flashController.reset();
          }
        }
      });
    }
  }

  void _setupStatusListener() {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      _statusSubscription = AuthService.userStatusStream(user.uid).listen((status) {
        if (status == 'suspended' || status == 'deleted' || status == 'rejected') {
          _forceLogout();
        }
      });
    }
  }

  Future<void> _forceLogout() async {
    await AuthService.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account has been suspended or removed.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _emergencySubscription?.cancel();
    _flashController.dispose();
    super.dispose();
  }

  final List<Widget> _views = [
    const DashboardView(),
    const EmergencyRequestsView(),
    const BookingsView(),
    const CustomersView(),
    const RevenueView(),
    const MyServicesView(),
    const ServiceInventoryView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      body: Row(
        children: [
          // Sidebar Wrapper
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                // Branding Logo Area
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D40D4),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF5D40D4,
                              ).withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.settings_suggest,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GearUp',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                              height: 1.2,
                            ),
                          ),
                          Text(
                            'Service Admin',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildNavItem(0, 'Dashboard', Icons.dashboard),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        1,
                        'Emergency Center',
                        Icons.emergency,
                        isEmergency: true,
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(2, 'Bookings', Icons.calendar_today),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        3,
                        'Customers',
                        Icons.people_alt,
                      ), // Original index 2
                      const SizedBox(height: 8),
                      _buildNavItem(
                        4,
                        'Revenue',
                        Icons.attach_money,
                      ), // Original index 3
                      const SizedBox(height: 8),
                      _buildNavItem(
                        5,
                        'My Services',
                        Icons.miscellaneous_services,
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        6,
                        'Spare Parts',
                        Icons.inventory_2_outlined,
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        7,
                        'Profile & Settings',
                        Icons.person_outline,
                      ),
                    ],
                  ),
                ),
                // Footer
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        // Cross-module navigation
                        // User profile section
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFF3E8FF),
                              radius: 18,
                              child: Icon(
                                Icons.person,
                                color: Color(0xFF5D40D4),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AuthService.currentUser?.email ??
                                      'Unknown User',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Service Admin',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Logout
                        InkWell(
                          onTap: () async {
                            await AuthService.signOut();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.logout,
                                  color: Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Logout',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main Body
          Expanded(child: _views[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon,
      {bool isEmergency = false}) {
    bool isSelected = _selectedIndex == index;
    bool hasPendingEmergency = isEmergency && _pendingEmergencies > 0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        Color? bgColor;
        Color? contentColor;

        if (isSelected) {
          if (isEmergency) {
            bgColor = Color.lerp(
              Colors.red.withValues(alpha: 0.1),
              Colors.red.withValues(alpha: 0.25),
              _pulseAnimation.value,
            );
            contentColor = Colors.red;
          } else {
            bgColor = const Color(0xFFF3E8FF);
            contentColor = const Color(0xFF5D40D4);
          }
        } else {
          if (hasPendingEmergency) {
            bgColor = Color.lerp(
              Colors.red.withValues(alpha: 0.05),
              Colors.red.withValues(alpha: 0.2),
              _pulseAnimation.value,
            );
            contentColor = Colors.red;
          } else {
            bgColor = Colors.transparent;
            contentColor = const Color(0xFF64748B);
          }
        }

        return InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: hasPendingEmergency
                  ? Border.all(
                      color: Colors.red.withValues(
                        alpha: 0.2 * _pulseAnimation.value,
                      ),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: contentColor,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight:
                          (isSelected || hasPendingEmergency) ? FontWeight.bold : FontWeight.w600,
                      color: contentColor,
                    ),
                  ),
                ),
                if (hasPendingEmergency)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _pendingEmergencies.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
