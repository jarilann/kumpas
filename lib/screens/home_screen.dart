import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'module_list_screen.dart';
import 'quiz_home_screen.dart';
import 'progress_screen.dart';
import 'badges_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // TODO: replace with real data from ProgressService once it exists.
  // Placeholder values match mockup screen 4 ("Layunin Ngayon" card).
  final String _currentGoalTitle = 'Kumpletuhin ang Modyul 1';
  final double _currentGoalPercent = 0.60;

  String get _displayName {
    final name = FirebaseAuth.instance.currentUser?.displayName;
    if (name == null || name.trim().isEmpty) {
      return 'Kaibigan'; // fallback greeting if no nickname is set
    }
    return name;
  }

  bool get _isGuest => FirebaseAuth.instance.currentUser?.isAnonymous ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.primaryBlue,

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==================================================
                // TOP BAR (info + settings icons)
                // ==================================================

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline,
                        color: AppColors.textWhite,
                      ),
                      onPressed: () {
                        // TODO: wire up info dialog/screen
                      },
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: AppColors.textWhite,
                      ),
                      onPressed: () {
                        // TODO: wire up settings screen
                      },
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: AppColors.textWhite,
                      ),
                      onPressed: () {
                        // AuthWrapper's stream picks this up and swaps
                        // back to OnboardingScreen automatically.
                        FirebaseAuth.instance.signOut();
                      },
                    ),
                  ],
                ),

                // ==================================================
                // GUEST BANNER (shown only for anonymous users)
                // ==================================================

                if (_isGuest)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Bisita mode — mag-sign up para ma-save ang iyong progreso.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // ==================================================
                // GREETING
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Magandang Araw, $_displayName!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                    const Text(
                      '👋',
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                const Text(
                  'Ipagpatuloy ang pagkatuto!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textWhiteMuted,
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // LAYUNIN NGAYON (current goal card)
                // ==================================================

                Container(
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: AppColors.accentYellow,
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Layunin Ngayon',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _currentGoalTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textWhite,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _currentGoalPercent,
                                minHeight: 10,
                                backgroundColor: Colors.white54,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.progressBar,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Text(
                            '${(_currentGoalPercent * 100).round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // TALAHANAYAN (quick action grid)
                // ==================================================

                const Text(
                  'Talahanayan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),

                const SizedBox(height: 6),
                const Divider(color: AppColors.textWhite),
                const SizedBox(height: 12),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.6,

                    children: [
                      _DashboardActionCard(
                        icon: Icons.menu_book,
                        label: 'Matuto',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ModuleListScreen(),
                            ),
                          );
                        },
                      ),

                      _DashboardActionCard(
                        icon: Icons.lightbulb,
                        label: 'Pagsusulit',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const QuizHomeScreen(),
                            ),
                          );
                        },
                      ),

                      _DashboardActionCard(
                        icon: Icons.show_chart,
                        label: 'Progreso',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ProgressScreen(),
                            ),
                          );
                        },
                      ),

                      _DashboardActionCard(
                        icon: Icons.emoji_events,
                        label: 'Mga Badge',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const BadgesScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD ACTION CARD (reusable grid item)
// ============================================================

class _DashboardActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentYellow,
      borderRadius: BorderRadius.circular(16),

      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: AppColors.textWhite,
            ),

            const SizedBox(height: 8),

            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
