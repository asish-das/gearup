import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gearup/services/navigation_service.dart';

import 'dashboard_view.dart';
import 'bookings_view.dart';
import 'customers_view.dart';
import 'revenue_view.dart';
import 'my_services_view.dart';
import 'profile_view.dart';

class ServiceScaffold extends StatefulWidget {
  const ServiceScaffold({super.key});

  @override
  State<ServiceScaffold> createState() => _ServiceScaffoldState();
}

class _ServiceScaffoldState extends State<ServiceScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _views = [
    const DashboardView(),
    const BookingsView(),
    const CustomersView(),
    const RevenueView(),
    const MyServicesView(),
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
                              color: const Color(0xFF5D40D4).withOpacity(0.2),
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
                      _buildNavItem(1, 'Bookings', Icons.calendar_today),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        2,
                        'Customers',
                        Icons.people_alt,
                      ), // Original index 2
                      const SizedBox(height: 8),
                      _buildNavItem(
                        3,
                        'Revenue',
                        Icons.attach_money,
                      ), // Original index 3
                      const SizedBox(height: 8),
                      _buildNavItem(
                        4,
                        'My Services',
                        Icons.miscellaneous_services,
                      ), // Original index 4
                      const SizedBox(height: 8),
                      _buildNavItem(
                        5,
                        'Profile & Settings',
                        Icons.person_outline,
                      ), // Changed from 'Settings' to 'Profile & Settings' and icon
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
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF5D40D4).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.swap_horiz,
                                color: Color(0xFF5D40D4),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Switch to Admin Portal',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF5D40D4),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    NavigationService.navigateToAdmin(context),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFF5D40D4),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text(
                                  'Go',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
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
                                  'John Doe',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Manager',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  Widget _buildNavItem(int index, String title, IconData icon) {
    bool isSelected = _selectedIndex == index;

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
          color: isSelected ? const Color(0xFFF3E8FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF5D40D4)
                  : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF5D40D4)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
