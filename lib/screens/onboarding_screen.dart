import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,

      body: SafeArea(
        child: Column(
          children: [
            // ------------------------------------------------
            // ONBOARDING PAGES
            // ------------------------------------------------
            Expanded(
              child: PageView(
                controller: _pageController,

                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },

                children: const [
                  SplashScreen(),
                  WelcomeScreen(),
                ],
              ),
            ),

            // ------------------------------------------------
            // PAGE INDICATOR
            // ------------------------------------------------
            SizedBox(
              height: 45,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(
                    active: _currentPage == 0,
                  ),

                  const SizedBox(width: 8),

                  _buildDot(
                    active: _currentPage == 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({
    required bool active,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),

      width: active ? 12 : 10,
      height: 10,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        color: active
            ? AppColors.accentYellow
            : AppColors.textWhite,
      ),
    );
  }
}