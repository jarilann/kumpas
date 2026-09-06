import 'module_model.dart';
import 'user_progress_model.dart';

/// One achievement badge — see mockup screen 14 ("Mga Badges").
///
/// There is exactly one badge per module (see [kBadgeDefinitions]),
/// using the real artwork in assets/images/badges/ — badge_modyul_1.png
/// through badge_modyul_8.png, one per entry in [kModules]. A badge is
/// [isEarned] once every lesson in its module is completed; this is
/// computed live from real Firestore lesson-progress state, not
/// stored separately.
class BadgeDefinition {
  final String moduleId;
  final String title;

  /// Path to the badge artwork, e.g.
  /// 'assets/images/badges/badge_modyul_1.png'. Must be covered by
  /// pubspec.yaml's `assets:` — see the `assets/images/badges/` entry.
  final String imageAsset;

  final bool Function(Map<String, LessonProgress> states) isEarned;

  const BadgeDefinition({
    required this.moduleId,
    required this.title,
    required this.imageAsset,
    required this.isEarned,
  });
}

bool _moduleCompleted(Map<String, LessonProgress> states, ModuleModel module) {
  return module.lessons.every((l) => states[l.id]?.completed == true);
}

/// One badge per module in [kModules], in the same order — earned by
/// completing every lesson within that module.
final List<BadgeDefinition> kBadgeDefinitions = [
  for (var i = 0; i < kModules.length; i++)
    BadgeDefinition(
      moduleId: kModules[i].id,
      title: 'Dalubhasa sa ${kModules[i].title}',
      imageAsset: 'assets/images/badges/badge_modyul_${i + 1}.png',
      isEarned: (states) => _moduleCompleted(states, kModules[i]),
    ),
];

List<BadgeDefinition> earnedBadges(Map<String, LessonProgress> states) {
  return kBadgeDefinitions.where((b) => b.isEarned(states)).toList();
}
