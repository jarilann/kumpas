import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final bool unlockedNext;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.unlockedNext,
  });

  @override
  Widget build(BuildContext context) {
    final passed = total > 0 && (score / total) >= 0.6;
    final starCount = total == 0
        ? 0
        : ((score / total) * 3).ceil().clamp(0, 3);

    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                passed ? 'Mahusay! 🎉' : 'Subukan Muli',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.emoji_events, size: 100, color: AppColors.accentYellow),
              const SizedBox(height: 24),
              const Text(
                'Iyong Marka',
                style: TextStyle(color: AppColors.textWhiteMuted, fontSize: 16),
              ),
              Text(
                '$score/$total',
                style: const TextStyle(
                  color: AppColors.accentYellow,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Icon(
                    i < starCount ? Icons.star : Icons.star_border,
                    color: AppColors.accentYellow,
                    size: 36,
                  );
                }),
              ),
              if (unlockedNext) ...[
                const SizedBox(height: 20),
                const Text(
                  'Nabuksan mo na ang susunod na aralin!',
                  style: TextStyle(color: AppColors.textWhite, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textWhite,
                        side: const BorderSide(color: AppColors.textWhite),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Suriin Muli'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentYellow,
                        foregroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Magpatuloy'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}