import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/module_model.dart';
import '../models/user_progress_model.dart';
import '../services/progress_service.dart';
import 'module_list_screen.dart';
import 'quiz_home_screen.dart';
import 'progress_screen.dart';
import 'badges_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, LessonProgress>> _statesFuture;

  @override
  void initState() {
    super.initState();
    _statesFuture = ProgressService.instance.getLessonStates(kModules);
  }

  String get _displayName {
    final name = FirebaseAuth.instance.currentUser?.displayName;
    if (name == null || name.trim().isEmpty) {
      return 'Kaibigan'; // fallback greeting if no nickname is set
    }
    return name;
  }

  bool get _isGuest => FirebaseAuth.instance.currentUser?.isAnonymous ?? false;

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tungkol sa KumpasKonek'),
        content: const Text(
          'Inklusibong Komunikasyon at Koneksyon sa Bawat Sensyas at '
          'Kumpas.\n\nMatuto ng Filipino Sign Language sa pamamagitan ng '
          'mga modyul, video demonstrasyon, at pagsusulit.\n\nBersyon 1.0.0',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

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
                      onPressed: _showInfoDialog,
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: AppColors.textWhite,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
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
                      color: Colors.black.withValues(alpha: 0.15),
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
                // LAYUNIN NGAYON (current goal card) — real progress
                // from ProgressService: the first module that's
                // unlocked but not yet fully completed.
                // ==================================================

                FutureBuilder<Map<String, LessonProgress>>(
                  future: _statesFuture,
                  builder: (context, snapshot) {
                    final states = snapshot.data;
                    String goalTitle = 'Kumpletuhin ang Modyul 1';
                    double goalPercent = 0;

                    if (states != null) {
                      final service = ProgressService.instance;
                      ModuleModel? pendingModule;
                      for (final m in kModules) {
                        if (service.isModuleUnlocked(m, states) &&
                            !service.isModuleCompleted(m, states)) {
                          pendingModule = m;
                          break;
                        }
                      }
                      if (pendingModule != null) {
                        goalTitle = 'Kumpletuhin ang ${pendingModule.number}';
                        goalPercent =
                            service.moduleProgressFraction(pendingModule, states);
                      } else {
                        // Every unlocked module is completed.
                        goalTitle = 'Nakumpleto mo na ang lahat ng modyul!';
                        goalPercent = 1;
                      }
                    }

                    return Container(
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
                            goalTitle,
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
                                    value: goalPercent,
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
                                '${(goalPercent * 100).round()}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textWhite,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
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
