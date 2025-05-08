import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

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
        
        // Create user profile in Firestore
        final userProfile = UserProfileModel(
          id: userCredential.user!.uid,
          email: email,
          displayName: email.split('@')[0], // Default display name from email
        );
        
        await _firestore
            .collection(_usersCollection)
            .doc(userCredential.user!.uid)
            .set(userProfile.toMap());
            
        debugPrint('User profile created in Firestore');
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
  
  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      debugPrint('Getting user profile for ID: $userId');
      final docSnapshot = await _firestore.collection(_usersCollection).doc(userId).get();
      
      if (docSnapshot.exists) {
        debugPrint('User profile found');
        return UserProfileModel.fromMap(docSnapshot.data() as Map<String, dynamic>, userId);
      } else {
        debugPrint('User profile not found, creating default profile');
        // If profile doesn't exist, create one with default values
        final userEmail = await getCurrentUserEmail();
        if (userEmail != null) {
          final defaultProfile = UserProfileModel(
            id: userId,
            email: userEmail,
            displayName: userEmail.split('@')[0],
          );
          
          await _firestore
              .collection(_usersCollection)
              .doc(userId)
              .set(defaultProfile.toMap());
              
          return defaultProfile;
        }
        return null;
      }
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }
  
  Future<bool> updateUserProfile(UserProfileModel profile) async {
    try {
      debugPrint('Updating user profile for ID: ${profile.id}');
      await _firestore
          .collection(_usersCollection)
          .doc(profile.id)
          .update({
        'displayName': profile.displayName,
        'photoUrl': profile.photoUrl,
      });
      
      // Update current user display name in Firebase Auth
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(profile.displayName);
        if (profile.photoUrl != null) {
          await user.updatePhotoURL(profile.photoUrl);
        }
      }
      
      debugPrint('User profile updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
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
