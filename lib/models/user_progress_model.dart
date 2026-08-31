/// Progress state for a single [LessonModel], stored per-user in
/// Firestore at:
///   users/{uid}/lessonProgress/{lessonId}
///
/// Locking works at the lesson level (not module level): the very
/// first lesson of the very first module is unlocked by default;
/// passing a lesson's quiz (>=60%) unlocks the next lesson in
/// sequence, whether that's the next lesson in the same module or
/// the first lesson of the next module.
class LessonProgress {
  final bool unlocked;
  final bool completed;
  final int score;
  final int total;
  final List<String> signsViewed;

  const LessonProgress({
    required this.unlocked,
    required this.completed,
    required this.score,
    required this.total,
    required this.signsViewed,
  });

  factory LessonProgress.initial({bool unlocked = false}) => LessonProgress(
        unlocked: unlocked,
        completed: false,
        score: 0,
        total: 0,
        signsViewed: const [],
      );

  Map<String, dynamic> toMap() => {
        'unlocked': unlocked,
        'completed': completed,
        'score': score,
        'total': total,
        'signsViewed': signsViewed,
      };

  factory LessonProgress.fromMap(Map<String, dynamic> map) => LessonProgress(
        unlocked: map['unlocked'] == true,
        completed: map['completed'] == true,
        score: (map['score'] as num?)?.toInt() ?? 0,
        total: (map['total'] as num?)?.toInt() ?? 0,
        signsViewed: List<String>.from(map['signsViewed'] ?? const []),
      );

  LessonProgress copyWith({
    bool? unlocked,
    bool? completed,
    int? score,
    int? total,
    List<String>? signsViewed,
  }) {
    return LessonProgress(
      unlocked: unlocked ?? this.unlocked,
      completed: completed ?? this.completed,
      score: score ?? this.score,
      total: total ?? this.total,
      signsViewed: signsViewed ?? this.signsViewed,
    );
  }
}
