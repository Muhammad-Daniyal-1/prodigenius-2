import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/sign_in.dart';
import 'screens/sign_up.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service before app starts
  final notificationService = NotificationService();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  await notificationService.requestPermissions();

  // Check if the user is already logged in
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');

  runApp(
    MyApp(
      isAuthenticated: userId != null,
      scaffoldMessengerKey: scaffoldMessengerKey,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  MyApp({
    super.key,
    required this.isAuthenticated,
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  }) : _scaffoldMessengerKey = scaffoldMessengerKey {
    // Start the deadline checker
    _startDeadlineChecker();
  }

  void _startDeadlineChecker() {
    final notificationService = NotificationService();
    notificationService.startDeadlineChecker();
    debugPrint('Deadline checker started in MyApp');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'Light Purple Auth',
      theme: ThemeData(
        fontFamily: 'Nunito',
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Nunito'),
          bodyMedium: TextStyle(fontFamily: 'Nunito'),
        ),
      ),
      initialRoute:
          isAuthenticated ? HomeScreen.routeName : SignInScreen.routeName,
      routes: {
        SignInScreen.routeName: (context) => const SignInScreen(),
        SignUpScreen.routeName: (context) => const SignUpScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        ForgotPasswordScreen.routeName:
            (context) => const ForgotPasswordScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
        // Profile update screen is handled via MaterialPageRoute with arguments
      },
    );
  }
}
