import 'package:flutter/material.dart';
import 'module_model.dart';
import 'user_progress_model.dart';

/// One achievement badge — see mockup screen 14 ("Mga Badges").
/// [isEarned] is computed from real Firestore lesson-progress state,
/// not stored separately.
class BadgeDefinition {
  final String title;
  final IconData icon;
  final Color color;
  final bool Function(Map<String, LessonProgress> states) isEarned;

  const BadgeDefinition({
    required this.title,
    required this.icon,
    required this.color,
    required this.isEarned,
  });
}

bool _lessonCompleted(Map<String, LessonProgress> states, String lessonId) {
  return states[lessonId]?.completed == true;
}

bool _allCompleted(Map<String, LessonProgress> states, List<String> lessonIds) {
  return lessonIds.every((id) => _lessonCompleted(states, id));
}

/// The six badges shown in the mockup, each tied to a real progress
/// condition:
///  - Alpabeto / Numero / Pagbati: completing that specific lesson.
///  - Idyoma: no dedicated idioms lesson exists in the current
///    content, so this is earned by completing all of Modyul 2
///    (greetings + polite expressions) — the closest equivalent to
///    "mastering expressions" available today.
///  - Unang Hakbang ("First Step"): completing any lesson at all.
///  - Mahusay na Tagasenyas ("Great Signer"): completing every
///    lesson across every module.
final List<BadgeDefinition> kBadgeDefinitions = [
  BadgeDefinition(
    title: 'Dalubhasa sa Alpabeto',
    icon: Icons.diamond_rounded,
    color: Colors.lightBlueAccent,
    isEarned: (states) => _lessonCompleted(states, 'alpabeto'),
  ),
  BadgeDefinition(
    title: 'Dalubhasa sa Numero',
    icon: Icons.hexagon_rounded,
    color: Colors.amber,
    isEarned: (states) => _lessonCompleted(states, 'numero'),
  ),
  BadgeDefinition(
    title: 'Dalubhasa sa Pagbati',
    icon: Icons.diamond_rounded,
    color: Colors.purpleAccent,
    isEarned: (states) => _lessonCompleted(states, 'pagbati'),
  ),
  BadgeDefinition(
    title: 'Dalubhasa sa Idyoma',
    icon: Icons.diamond_rounded,
    color: Colors.teal,
    isEarned: (states) =>
        _allCompleted(states, ['pagbati', 'magalang_na_pananalita']),
  ),
  BadgeDefinition(
    title: 'Unang Hakbang',
    icon: Icons.star_rounded,
    color: Colors.amber,
    isEarned: (states) => states.values.any((s) => s.completed),
  ),
  BadgeDefinition(
    title: 'Mahusay na Tagasenyas',
    icon: Icons.emoji_events_rounded,
    color: Colors.amber,
    isEarned: (states) => _allCompleted(
      states,
      [for (final m in kModules) for (final l in m.lessons) l.id],
    ),
  ),
];

List<BadgeDefinition> earnedBadges(Map<String, LessonProgress> states) {
  return kBadgeDefinitions.where((b) => b.isEarned(states)).toList();
}
