import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/lesson_model.dart';
import '../models/module_model.dart';
import '../models/user_progress_model.dart';
import '../services/progress_service.dart';
import '../widgets/module_widgets.dart';
import 'quiz_screen.dart';

/// Every module's lessons each get their own quiz entry here — e.g.
/// Modyul 1 shows both "Alpabeto" and "Numero" as separate rows,
/// Modyul 4 shows "Pamilya", "Paaralan", AND "Komunidad" separately —
/// mirroring how LessonListScreen lists lessons on the Matuto side.
/// Previously this screen showed one row per MODULE and silently
/// routed into whichever lesson wasn't finished yet, which made
/// multi-category modules (4, 5, 6, 8, and the 2-lesson modules 1,
/// 2, 3, 7) look like they only had a quiz for their first category.
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
            'Mga Modyul at Aralin',
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

                return ListView.builder(
                  itemCount: kModules.length,
                  itemBuilder: (context, moduleIndex) {
                    final module = kModules[moduleIndex];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: moduleIndex == kModules.length - 1 ? 0 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                module.icon,
                                color: AppColors.textWhite,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${module.number}: ${module.title}',
                                  style: const TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          for (final lesson in module.lessons)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _QuizLessonTile(
                                lesson: lesson,
                                state:
                                    states[lesson.id] ??
                                    LessonProgress.initial(unlocked: false),
                                onTap: () async {
                                  final state = states[lesson.id];
                                  if (state?.unlocked != true) return;
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => QuizScreen(
                                        module: module,
                                        lesson: lesson,
                                      ),
                                    ),
                                  );
                                  _refresh();
                                },
                              ),
                            ),
                        ],
                      ),
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

class _QuizLessonTile extends StatelessWidget {
  final LessonModel lesson;
  final LessonProgress state;
  final VoidCallback onTap;

  const _QuizLessonTile({
    required this.lesson,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scoreLabel = state.total > 0 ? '${state.score}/${state.total}' : null;

    return Material(
      color: AppColors.accentYellow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (state.completed && scoreLabel != null)
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
                !state.unlocked
                    ? Icons.lock_outline_rounded
                    : state.completed
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
