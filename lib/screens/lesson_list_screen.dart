import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/module_model.dart';
import '../models/user_progress_model.dart';
import '../services/progress_service.dart';
import '../widgets/module_widgets.dart';

/// Shows the lessons within a single [module] (e.g. Modyul 1's
/// "Alpabeto" and "Numero"), each downloadable/lockable on its own —
/// see mockup screen 6.
class LessonListScreen extends StatefulWidget {
  final ModuleModel module;

  const LessonListScreen({super.key, required this.module});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  late Future<Map<String, LessonProgress>> _statesFuture;

  @override
  void initState() {
    super.initState();
    _statesFuture = ProgressService.instance.getLessonStates(kModules);
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.module.number,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.module.title,
            style: const TextStyle(color: AppColors.textWhiteMuted, fontSize: 14),
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
                  itemCount: widget.module.lessons.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final lesson = widget.module.lessons[index];
                    final state = states[lesson.id] ??
                        LessonProgress.initial(unlocked: false);

                    return _LessonTile(
                      title: lesson.title,
                      state: state,
                      onTap: () {
                        if (!state.unlocked) return;
                        // Lesson content player (mockup screens 8/9)
                        // is built in a later step — for now just
                        // confirm the tap landed on an unlocked
                        // lesson.
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${lesson.title} — lesson content malapit na!',
                            ),
                          ),
                        );
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

class _LessonTile extends StatelessWidget {
  final String title;
  final LessonProgress state;
  final VoidCallback onTap;

  const _LessonTile({
    required this.title,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showProgressBar =
        state.unlocked && !state.completed && state.total > 0 && state.score > 0;
    final progress = state.total > 0 ? state.score / state.total : 0.0;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (state.unlocked)
                          const Icon(
                            Icons.download_rounded,
                            color: AppColors.textWhite,
                            size: 16,
                          ),
                      ],
                    ),
                    if (showProgressBar) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: Colors.white38,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.progressBar,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusIcon(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final LessonProgress state;
  const _StatusIcon({required this.state});

  @override
  Widget build(BuildContext context) {
    if (!state.unlocked) {
      return const Icon(Icons.lock_outline_rounded, color: AppColors.textWhite);
    }
    if (state.completed) {
      return const Icon(Icons.check_circle_rounded, color: AppColors.textWhite);
    }
    return const Icon(Icons.diamond_outlined, color: AppColors.textWhite);
  }
}
