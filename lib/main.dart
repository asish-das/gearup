import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:gearup/theme/app_theme.dart';
import 'package:gearup/config/firebase_config.dart';
import 'package:gearup/mobile_user/splash_screen.dart';
import 'package:gearup/mobile_user/onboarding_screen.dart';
import 'package:gearup/mobile_user/login_screen.dart';
import 'package:gearup/mobile_user/registration_screen.dart';
import 'package:gearup/mobile_user/main_navigation.dart';
import 'package:gearup/mobile_user/booking_screen.dart';
import 'package:gearup/mobile_user/service_tracking.dart';
import 'package:gearup/web_admin/admin_scaffold.dart';
import 'package:gearup/web_service/service_scaffold.dart';
import 'package:gearup/mobile_user/service_selection_screen.dart';
import 'package:gearup/mobile_user/emergency_screen.dart';
import 'package:gearup/services/auth_service.dart';
import 'package:gearup/models/user.dart';
import 'package:gearup/test_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  runApp(const GearUpApp());
}

class GearUpApp extends StatefulWidget {
  const GearUpApp({super.key});

  @override
  State<GearUpApp> createState() => _GearUpAppState();
}

class _GearUpAppState extends State<GearUpApp> {
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    AuthService.authStateChanges.listen((user) {
      setState(() {
        _currentUser = user != null
            ? null
            : null; // Will be updated with user data
        _isLoading = false;
      });
    });

    // Check initial auth state
    final user = AuthService.currentUser;
    if (user != null) {
      try {
        final userData = await AuthService.getUserData(user.uid);
        setState(() {
          _currentUser = userData;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _getInitialRoute() {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      // Not authenticated - show splash screen which will navigate to onboarding
      return const SplashScreen();
    }

    // Authenticated - route based on role and platform
    if (kIsWeb) {
      switch (_currentUser!.role) {
        case UserRole.vehicleOwner:
          return const MainNavigation(); // Vehicle owners use mobile app on web too
        case UserRole.serviceCenter:
          return const ServiceScaffold();
        case UserRole.admin:
          return const AdminScaffold();
      }
    } else {
      // Mobile - all authenticated users see mobile app
      return const MainNavigation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GearUp App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme.copyWith(
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      home: _getInitialRoute(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => _getInitialRoute());
          case '/onboarding':
            return MaterialPageRoute(
              builder: (context) => const OnboardingScreen(),
            );
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/registration':
            return MaterialPageRoute(
              builder: (context) => const RegistrationScreen(),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (context) => const MainNavigation(),
            );
          case '/booking':
            return MaterialPageRoute(
              builder: (context) => const BookingScreen(),
            );
          case '/service_selection':
            return MaterialPageRoute(
              builder: (context) => const ServiceSelectionScreen(),
            );
          case '/emergency':
            return MaterialPageRoute(
              builder: (context) => const EmergencyScreen(),
            );
          case '/tracking':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => ServiceTrackingScreen(
                isEmergency: args?['isEmergency'] ?? false,
                serviceName: args?['serviceName'],
                trackingId: args?['trackingId'],
              ),
            );
          case '/admin':
            return MaterialPageRoute(
              builder: (context) => const AdminScaffold(),
            );
          case '/test-auth':
            return MaterialPageRoute(
              builder: (context) => const AuthTestScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
            );
        }
      },
    );
  }
}
