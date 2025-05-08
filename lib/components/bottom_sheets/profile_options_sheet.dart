import 'package:flutter/material.dart';
import '../../models/user_profile_model.dart';
import '../../screens/profile_update_screen.dart';
import '../../screens/sign_in.dart';
import '../../services/firebase_service.dart';

class ProfileOptionsSheet extends StatelessWidget {
  final UserProfileModel userProfile;
  final FirebaseService firebaseService;
  final VoidCallback onProfileUpdated;

  const ProfileOptionsSheet({
    Key? key,
    required this.userProfile,
    required this.firebaseService,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator
          Center(
            child: Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          // User info header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.amber,
                  child: Text(
                    userProfile.displayName.isNotEmpty
                        ? userProfile.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProfile.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        userProfile.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 20),
          
          // Update Profile option
          ListTile(
            leading: const Icon(Icons.person, color: Colors.purple),
            title: const Text('Update Profile'),
            onTap: () async {
              Navigator.pop(context); // Close the bottom sheet
              
              // Navigate to profile update screen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileUpdateScreen(
                    userProfile: userProfile,
                  ),
                ),
              );
              
              // If profile was updated successfully, refresh the profile data
              if (result == true) {
                onProfileUpdated();
              }
            },
          ),
          
          // Logout option
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () async {
              try {
                await firebaseService.signOut();
                
                if (context.mounted) {
                  // Navigate to sign in screen and clear all previous routes
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    SignInScreen.routeName,
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.pop(context); // Close the bottom sheet
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
