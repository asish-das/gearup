import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gearup/services/navigation_service.dart';

import 'dashboard_view.dart';
import 'service_centers_view.dart';
import 'vehicle_owners_view.dart';
import 'bookings_manager_view.dart';
import 'system_settings_view.dart';
import 'admin_management_view.dart';

class AdminScaffold extends StatefulWidget {
  const AdminScaffold({super.key});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  final List<Widget> _views = [
    const DashboardView(),
    const ServiceCentersView(),
    const VehicleOwnersView(),
    const BookingsManagerView(),
    const Center(child: Text('Payments placeholder')),
    const Center(child: Text('Reports placeholder')),
    const Center(child: Text('AI Configuration placeholder')),
    const AdminManagementView(),
    const SystemSettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth < 1024;

    // Auto-collapse sidebar on mobile
    if (isMobile && !_isSidebarCollapsed) {
      _isSidebarCollapsed = true;
    } else if (!isMobile && _isSidebarCollapsed) {
      _isSidebarCollapsed = false;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Sidebar Wrapper
          if (!isMobile || (_isSidebarCollapsed && isMobile))
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isSidebarCollapsed ? 80 : 288,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                boxShadow: _isSidebarCollapsed
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(2, 0),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  // Branding Logo Area
                  Padding(
                    padding: EdgeInsets.all(_isSidebarCollapsed ? 16.0 : 24.0),
                    child: _isSidebarCollapsed
                        ? Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D40D4),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF5D40D4,
                                  ).withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.rocket_launch,
                              color: Colors.white,
                              size: 20,
                            ),
                          )
                        : Row(
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
                                      ).withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.rocket_launch,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (!_isSidebarCollapsed)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GearUp Admin',
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                        height: 1.2,
                                      ),
                                    ),
                                    Text(
                                      'Management Dashboard',
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
                  // Toggle button for tablet/desktop
                  if (!isMobile)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: IconButton(
                        onPressed: () => setState(
                          () => _isSidebarCollapsed = !_isSidebarCollapsed,
                        ),
                        icon: Icon(
                          _isSidebarCollapsed
                              ? Icons.expand_more
                              : Icons.expand_less,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  // Navigation Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildNavItem(0, 'Dashboard', Icons.dashboard_outlined),
                        const SizedBox(height: 4),
                        _buildNavItem(
                          1,
                          'Service Centers',
                          Icons.build_outlined,
                        ),
                        const SizedBox(height: 4),
                        _buildNavItem(
                          2,
                          'Vehicle Owners',
                          Icons.people_outline,
                        ),
                        const SizedBox(height: 4),
                        _buildNavItem(
                          3,
                          'Bookings',
                          Icons.calendar_month_outlined,
                        ),
                        const SizedBox(height: 4),
                        _buildNavItem(4, 'Payments', Icons.payments_outlined),
                        const SizedBox(height: 4),
                        _buildNavItem(5, 'Reports', Icons.bar_chart_outlined),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(color: Color(0xFFE2E8F0)),
                        ),
                        _buildNavItem(
                          6,
                          'AI Configuration',
                          Icons.smart_toy_outlined,
                        ),
                        const SizedBox(height: 4),
                        _buildNavItem(
                          7,
                          'Admin Management',
                          Icons.admin_panel_settings_outlined,
                        ),
                        const SizedBox(height: 4),
                        _buildNavItem(8, 'Settings', Icons.settings_outlined),
                      ],
                    ),
                  ),
                  // Footer
                  if (!_isSidebarCollapsed)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
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
                                  color: const Color(
                                    0xFF5D40D4,
                                  ).withOpacity(0.2),
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
                                      'Switch to Service Portal',
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF5D40D4),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        NavigationService.navigateToService(
                                          context,
                                        ),
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
                            // Logout
                            InkWell(
                              onTap: () {},
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
          // Mobile menu button
          if (isMobile)
            Container(
              width: 60,
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  IconButton(
                    onPressed: () => setState(
                      () => _isSidebarCollapsed = !_isSidebarCollapsed,
                    ),
                    icon: const Icon(Icons.menu, color: Color(0xFF5D40D4)),
                  ),
                ],
              ),
            ),
          // Main Body
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isMobile
                    ? double.infinity
                    : isTablet
                    ? 900
                    : 1200,
              ),
              child: _views[_selectedIndex],
            ),
          ),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5D40D4) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5D40D4).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
