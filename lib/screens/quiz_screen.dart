import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/module_model.dart';
import '../models/lesson_model.dart';
import '../services/progress_service.dart';
import '../widgets/module_widgets.dart';
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
      final order = List<int>.generate(q.options.length, (i) => i)..shuffle(rng);
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
            style: const TextStyle(color: AppColors.textWhiteMuted, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Tanong ${_currentQuestion + 1} / ${_questions.length}',
            style: const TextStyle(color: AppColors.textWhiteMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
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
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
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
                        question.options[index],
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