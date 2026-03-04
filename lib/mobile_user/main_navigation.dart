import 'package:flutter/material.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:gearup/mobile_user/home_dashboard.dart';
import 'package:gearup/mobile_user/service_centers.dart';
import 'package:gearup/mobile_user/service_history.dart';
import 'package:gearup/mobile_user/profile_page.dart';
import 'package:gearup/mobile_user/service_tracking.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  final List<Widget> _screens = [
    const HomeDashboard(),
    const ServiceCentersScreen(),
    const ServiceTrackingScreen(),
    const ServiceHistoryScreen(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: Colors.white54,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_city),
              label: 'CENTERS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.track_changes),
              label: 'TRACKING',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'HISTORY',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
          ],
          selectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
