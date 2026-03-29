import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthService {
  static final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  static Stream<auth.User?> get authStateChanges => _auth.authStateChanges();

  // Initialize and configure for development
  static Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('AuthService: Running in Debug Mode - Disabling App Verification for Testing');
      await _auth.setSettings(appVerificationDisabledForTesting: true);
    }
  }

  // Get current user
  static auth.User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  static Future<String> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phoneNumber,
    String? businessName,
  }) async {
    try {
      // Create user with email and password
      debugPrint('AuthService: Starting createUserWithEmailAndPassword for $email');
      auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        debugPrint('AuthService: createUserWithEmailAndPassword timed out');
        throw 'The authentication request timed out. Please check your internet connection and try again.';
      });
      debugPrint('AuthService: User created with UID: ${result.user?.uid}');

      // Create user document in Firestore
      User user = User(
        uid: result.user!.uid,
        email: email,
        name: name,
        role: role,
        phoneNumber: phoneNumber,
        businessName: businessName,
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
      );

      debugPrint('AuthService: Setting user document in Firestore');
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      debugPrint('AuthService: User document set successfully');
      
      return result.user!.uid;
    } on auth.FirebaseAuthException catch (e) {
      debugPrint('AuthService: FirebaseAuthException: ${e.code} - ${e.message}');
      throw e.message ?? 'An unknown authentication error occurred';
    } catch (e) {
      debugPrint('AuthService: Error during signUp: $e');
      throw e.toString();
    }
  }

  // Sign in with email and password
  static Future<String> signIn({
    required String email,
    required String password,
  }) async {
    try {
      auth.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user data from Firestore to check role
      User userData = await getUserData(result.user!.uid);
      if (userData.role != UserRole.vehicleOwner) {
        // Not a mobile user
        await _auth.signOut();
        throw 'Access Denied: This app is only for Vehicle Owners. Please use the web dashboard.';
      }

      if (userData.status == 'suspended') {
        await _auth.signOut();
        throw 'Your account has been suspended by the administrator. Please wait for approval.';
      }

      return result.user!.uid;
    } catch (e) {
      // Return clear error messages
      throw e.toString().replaceFirst(RegExp(r'^Exception: '), '');
    }
  }

  // Get user data from Firestore
  static Future<User> getUserData(String uid) async {
    int retries = 0;
    const maxRetries = 5;

    while (retries < maxRetries) {
      try {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          data['uid'] = doc.id;
          return User.fromMap(data);
        }
        
        // If not found, wait a bit and retry
        retries++;
        if (retries < maxRetries) {
          debugPrint('AuthService: User document not found for $uid, retrying ($retries/$maxRetries)...');
          await Future.delayed(Duration(milliseconds: 500 * retries));
        } else {
          throw 'User not found';
        }
      } catch (e) {
        if (retries >= maxRetries - 1) {
          debugPrint('AuthService: Error getting user data: $e');
          throw e.toString();
        }
        retries++;
        await Future.delayed(Duration(milliseconds: 500 * retries));
      }
    }
    throw 'User not found';
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw e.toString();
    }
  }

  // Update profile image url
  static Future<void> updateProfileImageUrl(String uid, String imageUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'profileImageUrl': imageUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update profile image: $e');
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw e.toString();
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }

      await _firestore.collection('users').doc(uid).update(updateData);
    } catch (e) {
      throw e.toString();
    }
  }

  // Delete user account
  static Future<void> deleteAccount(String uid) async {
    try {
      // Delete user document from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Delete user from Authentication
      await _auth.currentUser!.delete();
    } catch (e) {
      throw e.toString();
    }
  }
  // Get the current user's status in real-time
  static Stream<String?> userStatusStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? (doc.data() as Map<String, dynamic>)['status'] as String? : 'deleted');
  }
}
