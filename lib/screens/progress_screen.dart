import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/badge_model.dart';
import '../models/lesson_model.dart';
import '../models/module_model.dart';
import '../models/user_progress_model.dart';
import '../services/progress_service.dart';
import '../widgets/module_widgets.dart';

/// Real progress tracker (mockup screen 14, "Progreso"), built off
/// Firestore lesson-progress data via [ProgressService]. "Level" and
/// XP here are simple, transparent derivations from real completed-
/// lesson counts (100 XP per completed lesson) — not a separate
/// gamification system with its own stored state.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<Map<String, LessonProgress>> _statesFuture;

  @override
  void initState() {
    super.initState();
    _statesFuture = ProgressService.instance.getLessonStates(kModules);
  }

  String get _displayName {
    final name = FirebaseAuth.instance.currentUser?.displayName;
    if (name == null || name.trim().isEmpty) return 'Kaibigan';
    return name;
  }

  List<LessonModel> get _allLessons => [
        for (final m in kModules) ...m.lessons,
      ];

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progreso',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<Map<String, LessonProgress>>(
              future: _statesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.textWhite),
                  );
                }
                final states = snapshot.data!;
                final lessons = _allLessons;

                final completedLessons =
                    lessons.where((l) => states[l.id]?.completed == true).length;
                final attemptedQuizzes =
                    lessons.where((l) => (states[l.id]?.total ?? 0) > 0).length;
                final badgesEarned = earnedBadges(states).length;

                final xp = completedLessons * 100;
                final level = (xp ~/ 500) + 1;
                final xpIntoLevel = xp % 500;

                final service = ProgressService.instance;
                ModuleModel? pendingModule;
                for (final m in kModules) {
                  if (service.isModuleUnlocked(m, states) &&
                      !service.isModuleCompleted(m, states)) {
                    pendingModule = m;
                    break;
                  }
                }
                final pendingProgress = pendingModule == null
                    ? 0.0
                    : service.moduleProgressFraction(pendingModule, states);

                return ListView(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: AppColors.textWhite, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _displayName,
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Level $level',
                                style: const TextStyle(
                                  color: AppColors.textWhiteMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: xpIntoLevel / 500,
                        minHeight: 10,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(AppColors.progressBar),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$xpIntoLevel/500XP',
                      style: const TextStyle(color: AppColors.textWhiteMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Kabuuang Progreso',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Divider(color: AppColors.textWhite),
                    const SizedBox(height: 8),
                    _ProgressRow(
                      icon: Icons.menu_book_rounded,
                      label: 'Lesson na Nakumpleto',
                      value: '$completedLessons/${lessons.length}',
                    ),
                    _ProgressRow(
                      icon: Icons.lightbulb_rounded,
                      label: 'Pagsusulit na natapos',
                      value: attemptedQuizzes == 0
                          ? '0/${lessons.length}'
                          : '$attemptedQuizzes/${lessons.length} '
                              '(${(attemptedQuizzes / lessons.length * 100).round()}%)',
                    ),
                    _ProgressRow(
                      icon: Icons.emoji_events_rounded,
                      label: 'Mga Badge na nakuha',
                      value: '$badgesEarned/${kBadgeDefinitions.length}',
                    ),
                    const SizedBox(height: 20),
                    if (pendingModule != null) ...[
                      const Text(
                        'Nakabinbin na Modyul',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentYellow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white24,
                              child: Icon(pendingModule.icon, color: AppColors.textWhite),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pendingModule.number,
                                    style: const TextStyle(
                                      color: AppColors.textWhite,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    pendingModule.title,
                                    style: const TextStyle(
                                      color: AppColors.textWhiteMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: pendingProgress.clamp(0.0, 1.0),
                                            minHeight: 6,
                                            backgroundColor: Colors.white38,
                                            valueColor: const AlwaysStoppedAnimation(
                                              AppColors.progressBar,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(pendingProgress * 100).round()}%',
                                        style: const TextStyle(
                                          color: AppColors.textWhite,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProgressRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textWhite, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
