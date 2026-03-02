import 'package:flutter_test/flutter_test.dart';
import 'package:owner_app/services/auth_service.dart';
import 'package:owner_app/models/user.dart';

void main() {
  group('Authentication Service Tests', () {
    setUpAll(() async {
      // Initialize Flutter binding for testing
      TestWidgetsFlutterBinding.ensureInitialized();
      // Note: Firebase initialization would require actual Firebase project setup
      // For now, we'll test the service structure without Firebase
    });

    test('AuthService should be available', () {
      expect(AuthService.currentUser, isNotNull);
      expect(AuthService.authStateChanges, isNotNull);
    });

    test('UserRole enum should have correct values', () {
      expect(UserRole.vehicleOwner.displayName, 'Vehicle Owner');
      expect(UserRole.serviceCenter.displayName, 'Service Center');
      expect(UserRole.admin.displayName, 'Admin');
    });

    test('User model should create correctly', () {
      final user = User(
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.vehicleOwner,
        phoneNumber: '+1234567890',
      );

      expect(user.uid, 'test-uid');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.role, UserRole.vehicleOwner);
      expect(user.phoneNumber, '+1234567890');
    });

    test('User model should serialize to/from map', () {
      final user = User(
        uid: 'test-uid',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.serviceCenter,
        phoneNumber: '+1234567890',
      );

      final userMap = user.toMap();
      final userFromMap = User.fromMap(userMap);

      expect(userFromMap.uid, user.uid);
      expect(userFromMap.email, user.email);
      expect(userFromMap.name, user.name);
      expect(userFromMap.role, user.role);
      expect(userFromMap.phoneNumber, user.phoneNumber);
    });
  });
}
