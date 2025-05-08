import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signUp(String email, String password) async {
    try {
      debugPrint('Starting signup process for email: $email');
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint('User created successfully with UID: ${userCredential.user?.uid}');
      
      // Store user info in SharedPreferences after successful signup
      if (userCredential.user != null) {
        debugPrint('Storing user data in SharedPreferences');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', email);
        await prefs.setString('userId', userCredential.user!.uid);
        debugPrint('User data stored successfully');
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during signup: ${e.code}');
      debugPrint('Error message: ${e.message}');
      throw _getFirebaseAuthErrorMessage(e.code);
    } catch (e) {
      debugPrint('Unexpected error during signup: $e');
      throw 'An unexpected error occurred. Please try again. Error: $e';
    }
  }

  Future<UserCredential> signIn(String email, String password) async {
    try {
      debugPrint('Starting signin process for email: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint('User signed in successfully with UID: ${userCredential.user?.uid}');
      
      // Store user info in SharedPreferences after successful login
      if (userCredential.user != null) {
        debugPrint('Storing user data in SharedPreferences');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', email);
        await prefs.setString('userId', userCredential.user!.uid);
        debugPrint('User data stored successfully');
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during signin: ${e.code}');
      debugPrint('Error message: ${e.message}');
      throw _getFirebaseAuthErrorMessage(e.code);
    } catch (e) {
      debugPrint('Unexpected error during signin: $e');
      throw 'An unexpected error occurred. Please try again. Error: $e';
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('Starting signout process');
      await _auth.signOut();
      debugPrint('User signed out successfully');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('SharedPreferences cleared successfully');
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw 'Error signing out. Please try again.';
    }
  }

  Future<String?> getCurrentUserId() async {
    debugPrint('Getting current user ID');
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    debugPrint('Current user ID: $userId');
    return userId;
  }

  Future<String?> getCurrentUserEmail() async {
    debugPrint('Getting current user email');
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');
    debugPrint('Current user email: $userEmail');
    return userEmail;
  }

  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
