import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthService _authService = AuthService();
  bool _guestLoading = false;

  Future<void> _handleGuestContinue() async {
    setState(() => _guestLoading = true);

    final error = await _authService.continueAsGuest();

    if (!mounted) return;

    setState(() => _guestLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
    // On success, AuthWrapper's StreamBuilder in main.dart detects the
    // anonymous user and navigates to HomeScreen automatically.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                'MALIGAYANG\nPAGDATING!',
                style: TextStyle(
                  fontFamily: 'Chewy',
                  fontSize: 32,
                  color: AppColors.textWhite,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Matuto. Kumonekta.\nMakipagkomunikasyon',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textWhiteMuted,
                  height: 1.4,
                ),
              ),

              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/images/illustrate1.png',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 220,
                        height: 220,
                        decoration: const BoxDecoration(
                          color: AppColors.accentYellow,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sign_language,
                          size: 90,
                          color: AppColors.textWhite,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ------------------------------------------------
              // LOGIN BUTTON
              // ------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentYellow,
                    foregroundColor: AppColors.textWhite,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Mag-log in',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------
              // SIGN UP BUTTON
              // ------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textWhite,
                    side: const BorderSide(
                      color: AppColors.textWhite,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Mag-sign up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ------------------------------------------------
              // GUEST / BISITA
              // ------------------------------------------------
              Center(
                child: _guestLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textWhite,
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: _handleGuestContinue,
                        child: const Text(
                          'Magpatuloy bilang bisita',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}