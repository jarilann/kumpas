import 'package:flutter/material.dart';

import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loads any saved session from SharedPreferences before the app
  // renders anything, so AuthWrapper below knows immediately whether
  // someone is already signed in (replaces Firebase.initializeApp()).
  await AuthService.instance.init();

  runApp(const KumpasKonekApp());
}

class KumpasKonekApp extends StatelessWidget {
  const KumpasKonekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'KumpasKonek',
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

// The ONLY place that checks whether someone is logged in
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        if (!AuthService.instance.isReady) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (AuthService.instance.currentUser != null) {
          return const HomeScreen();
        }
        return const OnboardingScreen();
      },
    );
  }
}
