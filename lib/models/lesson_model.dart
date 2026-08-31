/// A single FSL sign taught within a lesson (e.g. the letter "A", or
/// the greeting "Magandang Umaga").
class SignModel {
  final String id;
  final String label; // e.g. "A", "Isa", "Magandang Umaga"
  final String meaning; // "Kahulugan"
  final String description; // "Deskripsyon"

  /// Path to the real demonstration video once it exists (e.g.
  /// 'assets/videos/alpabeto_a.mp4'). Null while content is still
  /// placeholder/dummy.
  final String? videoAssetPath;

  const SignModel({
    required this.id,
    required this.label,
    required this.meaning,
    required this.description,
    this.videoAssetPath,
  });
}

/// A single multiple-choice quiz question tied to a lesson.
class QuizQuestionModel {
  final String question;
  final String signLabel; // which sign this question shows/refers to
  final List<String> options;
  final int correctIndex;

  const QuizQuestionModel({
    required this.question,
    required this.signLabel,
    required this.options,
    required this.correctIndex,
  });
}

/// A sub-lesson within a module (e.g. Modyul 1 "Alpabeto at Numero"
/// contains the lessons "Alpabeto" and "Numero" separately — see
/// mockup screens 5/6). Progress, locking, and quizzes are tracked
/// per lesson, not per module.
class LessonModel {
  final String id;
  final String title; // "Alpabeto", "Numero", "Mga Pagbati"...
  final List<SignModel> signs;
  final List<QuizQuestionModel> quiz;

  const LessonModel({
    required this.id,
    required this.title,
    required this.signs,
    required this.quiz,
  });
}
/// A module is a collection of lessons
//