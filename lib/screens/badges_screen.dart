import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/badge_model.dart';
import '../models/module_model.dart';
import '../models/user_progress_model.dart';
import '../services/progress_service.dart';
import '../widgets/module_widgets.dart';

/// Real badges grid (mockup screen 14, "Mga Badges"), driven by
/// [kBadgeDefinitions] against actual Firestore lesson-progress state.
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
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
          const Text(
            'Mga Badge',
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

                return GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.95,
                  children: [
                    for (final badge in kBadgeDefinitions)
                      _BadgeTile(badge: badge, earned: badge.isEarned(states)),
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

class _BadgeTile extends StatelessWidget {
  final BadgeDefinition badge;
  final bool earned;

  const _BadgeTile({required this.badge, required this.earned});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            earned ? badge.icon : Icons.lock_rounded,
            size: 40,
            color: earned ? badge.color : Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: earned ? AppColors.primaryBlue : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
