import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/module_model.dart';
import '../models/lesson_model.dart';
import '../models/user_progress_model.dart';
import '../services/progress_service.dart';
import '../widgets/module_widgets.dart';
import 'quiz_screen.dart';

class QuizHomeScreen extends StatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  State<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends State<QuizHomeScreen> {
  late Future<Map<String, LessonProgress>> _statesFuture;

  @override
  void initState() {
    super.initState();
    _statesFuture = ProgressService.instance.getLessonStates(kModules);
  }

  Future<void> _refresh() async {
    setState(() {
      _statesFuture = ProgressService.instance.getLessonStates(kModules);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pagsusulit',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mga Modyul',
            style: TextStyle(color: AppColors.textWhiteMuted, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<Map<String, LessonProgress>>(
              future: _statesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.textWhite,
                    ),
                  );
                }
                final states = snapshot.data!;

                return ListView.separated(
                  itemCount: kModules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final module = kModules[index];
                    // Use the module's first lesson to represent overall
                    // unlock/score status on this summary screen.
                    final firstLesson = module.lessons.first;
                    final state = states[firstLesson.id];
                    final unlocked = state?.unlocked ?? false;
                    final completed = module.lessons.every(
                      (l) => states[l.id]?.completed == true,
                    );

                    // Combined score across all lessons in the module.
                    int totalScore = 0;
                    int totalPossible = 0;
                    for (final lesson in module.lessons) {
                      final s = states[lesson.id];
                      if (s != null) {
                        totalScore += s.score;
                        totalPossible += s.total;
                      }
                    }

                    return _QuizModuleTile(
                      module: module,
                      unlocked: unlocked,
                      completed: completed,
                      scoreLabel: totalPossible > 0
                          ? '$totalScore/$totalPossible'
                          : null,
                      onTap: () async {
                        if (!unlocked) return;
                        // Jump into the first unlocked (or first
                        // incomplete) lesson's quiz.
                        final targetLesson = module.lessons.firstWhere(
                          (l) => states[l.id]?.completed != true,
                          orElse: () => module.lessons.first,
                        );
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(
                              module: module,
                              lesson: targetLesson,
                            ),
                          ),
                        );
                        _refresh();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizModuleTile extends StatelessWidget {
  final ModuleModel module;
  final bool unlocked;
  final bool completed;
  final String? scoreLabel;
  final VoidCallback onTap;

  const _QuizModuleTile({
    required this.module,
    required this.unlocked,
    required this.completed,
    required this.scoreLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentYellow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: Icon(module.icon, color: AppColors.textWhite),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.number,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (completed && scoreLabel != null)
                      Text(
                        'Marka: $scoreLabel',
                        style: const TextStyle(
                          color: AppColors.textWhiteMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                !unlocked
                    ? Icons.lock_outline_rounded
                    : completed
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: AppColors.textWhite,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
