import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:gearup/services/auth_service.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:gearup/mobile_user/home_dashboard.dart';
import 'package:gearup/mobile_user/service_centers.dart';
import 'package:gearup/mobile_user/service_history.dart';
import 'package:gearup/mobile_user/profile_page.dart';
import 'package:gearup/mobile_user/service_tracking.dart';
import 'package:gearup/mobile_user/ai_chat_modal.dart';
import 'package:gearup/mobile_user/supermarket_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  StreamSubscription? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
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

  List<Widget> get _screens => [
    HomeDashboard(onTabSelected: (index) {
      setState(() => _currentIndex = index);
    }),
    const SupermarketScreen(),
    const ServiceCentersScreen(),
    const ServiceTrackingScreen(),
    const ServiceHistoryScreen(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
              ),
              child: const AIChatModal(),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        elevation: 4,
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
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
              icon: Icon(Icons.shopping_cart),
              label: 'SHOP',
            ),
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
