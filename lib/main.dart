import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/sign_in.dart';
import 'screens/sign_up.dart';
import 'screens/home.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Check if the user is already logged in
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');

  runApp(MyApp(isAuthenticated: userId != null));
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;

  const MyApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      },
    );
  }
}
