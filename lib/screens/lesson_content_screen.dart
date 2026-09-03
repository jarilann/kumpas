import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/module_model.dart';
import '../models/lesson_model.dart';
import '../services/progress_service.dart';
import '../widgets/module_widgets.dart';
import 'quiz_screen.dart';

class LessonContentScreen extends StatefulWidget {
  final ModuleModel module;
  final LessonModel lesson;

  const LessonContentScreen({
    super.key,
    required this.module,
    required this.lesson,
  });

  @override
  State<LessonContentScreen> createState() => _LessonContentScreenState();
}

class _LessonContentScreenState extends State<LessonContentScreen> {
  int _currentIndex = 0;
  bool _loading = true;
  bool _alreadyViewedAll = false;

  /// 1 or 2 — which variant is currently shown, for signs that have
  /// more than one accepted version (see [SignModel.hasVariant]).
  int _selectedVariant = 1;

  @override
  void initState() {
    super.initState();
    _checkExistingProgress();
  }

  Future<void> _checkExistingProgress() async {
    final states = await ProgressService.instance.getLessonStates(kModules);
    final state = states[widget.lesson.id];

    if (!mounted) return;

    final allSignIds = widget.lesson.signs.map((s) => s.id).toSet();
    final viewedIds = state?.signsViewed.toSet() ?? {};
    final viewedAll =
        allSignIds.isNotEmpty && allSignIds.every(viewedIds.contains);

    setState(() {
      _alreadyViewedAll = viewedAll && state?.completed != true;
      _loading = false;
    });
  }

  void _goToQuiz() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            QuizScreen(module: widget.module, lesson: widget.lesson),
      ),
    );
  }

  Future<void> _markCurrentSignViewed() async {
    final sign = widget.lesson.signs[_currentIndex];
    await ProgressService.instance.markSignViewed(
      widget.lesson.id,
      sign.id,
      kModules,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.primaryBlue,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.textWhite),
        ),
      );
    }

    if (_alreadyViewedAll) {
      return ModuleScaffold(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.lesson.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Natapos mo na ang mga senyas na ito. Magpatuloy sa pagsusulit o balikan muli ang mga aralin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textWhiteMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _goToQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentYellow,
                foregroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Magpatuloy sa Pagsusulit'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() => _alreadyViewedAll = false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textWhite,
                side: const BorderSide(color: AppColors.textWhite),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Balikan ang mga Aralin'),
            ),
          ],
        ),
      );
    }

    final sign = widget.lesson.signs[_currentIndex];
    final isLast = _currentIndex == widget.lesson.signs.length - 1;

    return ModuleScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.module.number} - ${widget.lesson.title}',
            style: const TextStyle(
              color: AppColors.textWhiteMuted,
              fontSize: 13,
            ),
          ),
          Text(
            'Senyas: ${sign.label}',
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 180,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.play_circle_outline,
                        color: AppColors.textWhite,
                        size: 48,
                      ),
                    ),
                    if (sign.hasVariant) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _VariantButton(
                              label: 'Var 1',
                              selected: _selectedVariant == 1,
                              onTap: () => setState(() => _selectedVariant = 1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _VariantButton(
                              label: 'Var 2',
                              selected: _selectedVariant == 2,
                              onTap: () => setState(() => _selectedVariant = 2),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Kahulugan: ${sign.meaning}',
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sign.description,
                      style: const TextStyle(
                        color: AppColors.textWhiteMuted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_currentIndex > 0)
                OutlinedButton(
                  onPressed: () => setState(() {
                    _currentIndex--;
                    _selectedVariant = 1;
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textWhite,
                    side: const BorderSide(color: AppColors.textWhite),
                  ),
                  child: const Text('Nakaraan'),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  await _markCurrentSignViewed();
                  if (!mounted) return;

                  if (isLast) {
                    _goToQuiz();
                  } else {
                    setState(() {
                      _currentIndex++;
                      _selectedVariant = 1;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentYellow,
                  foregroundColor: AppColors.primaryBlue,
                ),
                child: Text(isLast ? 'Pagsusulit' : 'Susunod'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The "Var 1" / "Var 2" toggle shown for signs with more than one
/// accepted version — see mockup screen 9.
class _VariantButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VariantButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.accentYellow : Colors.transparent,
        foregroundColor: selected ? AppColors.primaryBlue : AppColors.textWhite,
        side: const BorderSide(color: AppColors.textWhite),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
