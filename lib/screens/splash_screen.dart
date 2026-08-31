import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              // --------------------------------------------------
              // TOP SPACE
              // --------------------------------------------------
              const Spacer(flex: 2),

              // --------------------------------------------------
              // LOGO
              // --------------------------------------------------
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
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

              const SizedBox(height: 32),

              // --------------------------------------------------
              // APP NAME
              // --------------------------------------------------
              const Center(
                child: Text(
                  'KUMPASKONEK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Chewy',
                    fontSize: 34,
                    color: AppColors.textWhite,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // TAGLINE
              // --------------------------------------------------
              const Center(
                child: Text(
                  'Inklusibong Komunikasyon at Koneksyon sa\n'
                  'Bawat Senyas at Kumpas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textWhiteMuted,
                    height: 1.3,
                  ),
                ),
              ),

              // --------------------------------------------------
              // BOTTOM SPACE
              // --------------------------------------------------
              const Spacer(flex: 2),

              // The page dots are handled by OnboardingScreen.
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}