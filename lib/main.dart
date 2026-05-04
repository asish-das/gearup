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
import 'package:gearup/web_auth/web_login_screen.dart';
import 'package:gearup/mobile_user/service_selection_screen.dart';
import 'package:gearup/mobile_user/emergency_screen.dart';
import 'package:gearup/services/auth_service.dart';
import 'package:gearup/models/user.dart';
import 'package:gearup/test_auth.dart';
import 'package:gearup/access_denied_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  await AuthService.initialize(); // Initialize our auth settings
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
    AuthService.authStateChanges.listen((user) async {
      // If we are explicitly processing auth (registration/login), skip automatic updates
      // to avoid race conditions and unexpected navigation jumps.
      if (AuthService.isProcessingAuth) {
        debugPrint('Main: Auth state change ignored because AuthService is processing auth.');
        return;
      }

      try {
        if (user != null) {
          debugPrint('Main: Auth state change: User is logged in (${user.uid}). Fetching data...');
          final userData = await AuthService.getUserData(user.uid);
          if (mounted) {
            setState(() {
              _currentUser = userData;
              _isLoading = false;
            });
          }
        } else {
          debugPrint('Main: Auth state change: No user logged in.');
          if (mounted) {
            setState(() {
              _currentUser = null;
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        debugPrint('Main: Error in auth listener: $e');
        // If we can't get data for a logged in user, better to logout to avoid desync
        await AuthService.signOut();
        if (mounted) {
          setState(() {
            _currentUser = null;
            _isLoading = false;
          });
        }
      }
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
      // Not authenticated - show different screens based on platform
      if (kIsWeb) {
        return const WebLoginScreen(); // Web shows login screen
      } else {
        return const SplashScreen(); // Mobile shows splash screen
      }
    }

    // Authenticated - route based on role and platform
    if (kIsWeb) {
      switch (_currentUser!.role) {
        case UserRole.serviceCenter:
          if (_currentUser!.status == 'pending') {
            return const WebApprovalPendingScreen();
          } else if (_currentUser!.status == 'suspended') {
            return const WebAccountSuspendedScreen();
          }
          return const ServiceScaffold();
        case UserRole.admin:
        case UserRole.superAdmin:
          // Admin bypass for bootstrap email
          if (_currentUser!.email != 'admin@gmail.com') {
            if (_currentUser!.status == 'pending') {
              return const WebApprovalPendingScreen();
            } else if (_currentUser!.status == 'suspended') {
              return const WebAccountSuspendedScreen();
            }
          }
          return const AdminScaffold();
        default:
          return const WebAccessDeniedScreen();
      }
    } else {
      // Mobile
      if (_currentUser!.role == UserRole.vehicleOwner) {
        if (_currentUser!.status == 'suspended') {
          return const WebAccountSuspendedScreen();
        }
        return const MainNavigation();
      }
      return const MobileAccessDeniedScreen();
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
              settings: settings,
              builder: (context) => const BookingScreen(),
            );
          case '/service_selection':
            return MaterialPageRoute(
              settings: settings,
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
          case '/admin-login':
            return MaterialPageRoute(
              builder: (context) => const WebLoginScreen(),
            );
          case '/service-login':
            return MaterialPageRoute(
              builder: (context) => const WebLoginScreen(),
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
