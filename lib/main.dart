import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Without this, offline support is unreliable: it's on by default for
  // Android/iOS but NOT for web, and the default cache size can evict
  // a signed-in user's lesson progress if enough other data is cached.
  // Explicitly enabling it here makes "log in once, then works offline"
  // consistent across every platform this app ships on.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const OnboardingScreen();
      },
    );
  }
}
