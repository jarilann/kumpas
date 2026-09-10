import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/module_model.dart';
import '../models/lesson_model.dart';
import '../services/progress_service.dart';
import '../widgets/module_widgets.dart';
import '../widgets/sign_video_player.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final ModuleModel module;
  final LessonModel lesson;

  const QuizScreen({super.key, required this.module, required this.lesson});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<QuizQuestionModel> _questions;
  int _currentQuestion = 0;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;

  /// 1, 2, or 3 — which of the referenced sign's accepted video
  /// versions is currently shown (see [SignModel.hasVariant]).
  /// Resets to 1 whenever a new question loads.
  int _selectedVariant = 1;

  @override
  void initState() {
    super.initState();
    _questions = _shuffledQuiz(widget.lesson.quiz);
  }

  /// Returns a fresh copy of [source] with the question order shuffled
  /// and, independently, each question's own answer options shuffled —
  /// so neither the question sequence nor "always option 2" can be
  /// memorized across attempts.
  List<QuizQuestionModel> _shuffledQuiz(List<QuizQuestionModel> source) {
    final rng = Random();
    final questions = List<QuizQuestionModel>.from(source)..shuffle(rng);
    return questions.map((q) {
      final order = List<int>.generate(q.options.length, (i) => i)
        ..shuffle(rng);
      final shuffledOptions = [for (final i in order) q.options[i]];
      final newCorrectIndex = order.indexOf(q.correctIndex);
      return QuizQuestionModel(
        question: q.question,
        signLabel: q.signLabel,
        options: shuffledOptions,
        correctIndex: newCorrectIndex,
      );
    }).toList();
  }

  /// The question shows "Anong letra/senyas ito?" (What letter/sign is
  /// this?) — it needs the actual sign's video as visual reference, so
  /// this looks up the matching [SignModel] by [QuizQuestionModel.signLabel].
  SignModel? _signFor(String label) {
    for (final s in widget.lesson.signs) {
      if (s.label == label) return s;
    }
    return null;
  }

  /// Display-only transform: shows "Orange / Kahel" instead of just
  /// "Orange" for any option that matches a sign in this lesson. The
  /// underlying [option] string itself is untouched — quiz checking
  /// in [_selectOption] compares indices, not text, so this never
  /// affects correctness.
  String _getOptionDisplay(String option) {
    for (final sign in widget.lesson.signs) {
      if (sign.label == option) {
        return '${sign.label} / ${sign.meaning}';
      }
    }
    return option;
  }

  void _selectOption(int optionIndex) {
    if (_answered) return;

    final question = _questions[_currentQuestion];
    final isCorrect = optionIndex == question.correctIndex;

    setState(() {
      _selectedOption = optionIndex;
      _answered = true;
      if (isCorrect) _score++;
    });
  }

  Future<void> _nextQuestion() async {
    final isLast = _currentQuestion == _questions.length - 1;

    if (!isLast) {
      setState(() {
        _currentQuestion++;
        _selectedOption = null;
        _answered = false;
        _selectedVariant = 1;
      });
      return;
    }

    // Last question answered — submit the result.
    final unlockedNext = await ProgressService.instance.submitQuizResult(
      lessonId: widget.lesson.id,
      score: _score,
      total: _questions.length,
      modules: kModules,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          score: _score,
          total: _questions.length,
          unlockedNext: unlockedNext,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestion];
    final referencedSign = _signFor(question.signLabel);

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
          Text(
            widget.lesson.title,
            style: const TextStyle(
              color: AppColors.textWhiteMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tanong ${_currentQuestion + 1} / ${_questions.length}',
            style: const TextStyle(
              color: AppColors.textWhiteMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          if (referencedSign != null)
            Container(
              height: 300,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SignVideoPlayer(
                      // Keyed on the question index AND the selected
                      // variant, so switching versions — or moving to
                      // a repeated sign in a later question — always
                      // gets a fresh, autoplaying-from-start controller.
                      key: ValueKey(
                        'quiz_${_currentQuestion}_${referencedSign.id}_$_selectedVariant',
                      ),
                      assetPath: switch (_selectedVariant) {
                        3 => referencedSign.videoAssetPathVar3,
                        2 => referencedSign.videoAssetPathVar2,
                        _ => referencedSign.videoAssetPath,
                      },
                    ),
                  ),
                  if (referencedSign.hasVariant) ...[
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
                        if (referencedSign.hasThirdVariant) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _VariantButton(
                              label: 'Var 3',
                              selected: _selectedVariant == 3,
                              onTap: () =>
                                  setState(() => _selectedVariant = 3),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            question.question,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              itemCount: question.options.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.8,
              ),
              itemBuilder: (context, index) {
                final isSelected = _selectedOption == index;
                final isCorrectOption = index == question.correctIndex;

                Color bgColor = AppColors.accentYellow;
                if (_answered) {
                  if (isCorrectOption) {
                    bgColor = Colors.green;
                  } else if (isSelected) {
                    bgColor = Colors.redAccent;
                  } else {
                    bgColor = AppColors.accentYellow.withValues(alpha: 0.4);
                  }
                }

                return Material(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _selectOption(index),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _getOptionDisplay(question.options[index]),
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_answered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentYellow,
                  foregroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _currentQuestion == _questions.length - 1
                      ? 'Tapusin'
                      : 'Susunod',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The "Var 1" / "Var 2" / "Var 3" toggle for signs with more than one
/// accepted version — same widget/styling as the one on
/// lesson_content_screen.dart's sign viewer, duplicated here (private
/// to this file) rather than shared, since neither screen imports
/// from the other.
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
