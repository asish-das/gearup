import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../services/navigation_service.dart';
import '../services/auth_service.dart';
import 'dashboard_view.dart';
import 'service_centers_view.dart';
import 'bookings_manager_view.dart';
import 'vehicle_owners_view.dart';
import 'admin_management_view.dart';
import 'system_settings_view.dart';
import 'payments_view.dart';
import 'reports_view.dart';

class AdminScaffold extends StatefulWidget {
  const AdminScaffold({super.key});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _setupStatusListener();
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
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
    super.dispose();
  }

  List<Widget> get _views => [
    DashboardView(
      onNavigate: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    ),
    const ServiceCentersView(),
    const VehicleOwnersView(),
    const BookingsManagerView(),
    const PaymentsView(),
    const ReportsView(),
    const Center(child: Text('AI Configuration placeholder')),
    const AdminManagementView(),
    const SystemSettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    // Auto collapse for tablet
    final bool showSidebar = !isMobile;
    final bool isCollapsed = isTablet || _isSidebarCollapsed;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF0F172A)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(
                'GearUp Admin',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: const Color(0xFFE2E8F0), height: 1),
              ),
            )
          : null,
      drawer: isMobile
          ? Drawer(child: SafeArea(child: _buildSidebarContent(false, true)))
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar Wrapper for Desktop/Tablet
          if (showSidebar)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isCollapsed ? 80 : 280,
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  right: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: _buildSidebarContent(isCollapsed, false),
            ),

          // Main Body
          Expanded(
            child: Column(
              children: [
                // Top Header area for Desktop/Tablet
                if (showSidebar)
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (!isTablet)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isSidebarCollapsed = !_isSidebarCollapsed;
                              });
                            },
                            icon: Icon(
                              isCollapsed ? Icons.menu_open : Icons.menu,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        const Spacer(),
                        // Header actions (e.g. notifications, profile)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Admin Active',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Content View
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _views[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(bool isCollapsed, bool isMobileDrawer) {
    return Column(
      children: [
        // Branding Logo Area
        Container(
          padding: EdgeInsets.all(isCollapsed ? 16.0 : 24.0),
          alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
          child: isCollapsed
              ? Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5D40D4), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
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
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5D40D4), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF5D40D4,
                            ).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.rocket_launch,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GearUp',
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'Admin Hub',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 16,
              vertical: 8,
            ),
            children: [
              _buildSectionTitle('CORE', isCollapsed),
              _buildNavItem(
                0,
                'Dashboard',
                Icons.dashboard_outlined,
                isCollapsed,
                isMobileDrawer,
              ),
              const SizedBox(height: 6),
              _buildNavItem(
                1,
                'Service Centers',
                Icons.storefront_outlined,
                isCollapsed,
                isMobileDrawer,
              ),
              const SizedBox(height: 6),
              _buildNavItem(
                2,
                'Vehicle Owners',
                Icons.people_outline,
                isCollapsed,
                isMobileDrawer,
              ),

              const SizedBox(height: 16),
              _buildSectionTitle('OPERATIONS', isCollapsed),
              _buildNavItem(
                3,
                'Bookings',
                Icons.calendar_month_outlined,
                isCollapsed,
                isMobileDrawer,
              ),
              const SizedBox(height: 6),
              _buildNavItem(
                4,
                'Payments',
                Icons.payments_outlined,
                isCollapsed,
                isMobileDrawer,
              ),
              const SizedBox(height: 6),
              _buildNavItem(
                5,
                'Reports',
                Icons.bar_chart_outlined,
                isCollapsed,
                isMobileDrawer,
              ),

              const SizedBox(height: 16),
              _buildSectionTitle('SYSTEM', isCollapsed),
              _buildNavItem(
                6,
                'AI Config',
                Icons.smart_toy_outlined,
                isCollapsed,
                isMobileDrawer,
              ),
              const SizedBox(height: 6),
              _buildNavItem(
                7,
                'Staff',
                Icons.admin_panel_settings_outlined,
                isCollapsed,
                isMobileDrawer,
              ),
              const SizedBox(height: 6),
              _buildNavItem(
                8,
                'Settings',
                Icons.settings_outlined,
                isCollapsed,
                isMobileDrawer,
              ),
            ],
          ),
        ),

        // Footer Switch Button
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: InkWell(
              onTap: () => NavigationService.navigateToService(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.swap_horiz,
                        color: Color(0xFF5D40D4),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Service Portal',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Footer Action (Logout)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: InkWell(
            onTap: () async {
              await AuthService.signOut();
              if (!mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(isCollapsed ? 12 : 12),
              child: Row(
                mainAxisAlignment: isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  const Icon(Icons.logout, color: Color(0xFFEF4444), size: 20),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Log out',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isCollapsed) {
    if (isCollapsed) return const SizedBox(height: 0);
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String title,
    IconData icon,
    bool isCollapsed,
    bool isMobileDrawer,
  ) {
    bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (isMobileDrawer) {
          Navigator.pop(context); // Close Drawer
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isCollapsed ? 0 : 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5D40D4).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected && !isCollapsed
              ? const Border(
                  left: BorderSide(color: Color(0xFF5D40D4), width: 3),
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: isCollapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF5D40D4)
                  : const Color(0xFF64748B),
              size: 22,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF5D40D4)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
