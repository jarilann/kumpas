/// A single FSL sign taught within a lesson (e.g. the letter "A", or
/// the greeting "Magandang Umaga").
class SignModel {
  final String id;
  final String label; // e.g. "A", "Isa", "Magandang Umaga"
  final String meaning; // "Kahulugan"
  final String description; // "Deskripsyon"

  /// Path to the demonstration video bundled as a local Flutter asset
  /// (e.g. 'assets/videos/modyul_1/alpabeto/a.mp4') — must be listed
  /// under pubspec.yaml's `assets:`. Resolved directly via
  /// VideoPlayerController.asset() at runtime. This is always "Var 1"
  /// when [videoAssetPathVar2] is also set. Null while a sign has no
  /// video bundled yet.
  final String? videoAssetPath;

  /// Path to a second, alternate demonstration video for signs that
  /// have more than one accepted way of signing them (e.g. regional
  /// variants) — see mockup screen 9, which shows "Var 1" / "Var 2"
  /// buttons. Leave null for signs that only have one version; the
  /// lesson screen only shows the variant picker when this is set.
  /// Naming convention: same path as [videoAssetPath], with "_var2"
  /// appended before the extension, e.g.
  /// 'assets/videos/modyul_1/alpabeto/a.mp4' -> '..._var2.mp4'.
  final String? videoAssetPathVar2;

  /// Storage/asset path to a third accepted version, for the rare
  /// signs that have three (e.g. "Brown"). Only meaningful when
  /// [videoAssetPathVar2] is also set. Same "_var3" naming convention.

  final String? videoAssetPathVar3;

  bool get hasVariant => videoAssetPathVar2 != null;
  bool get hasThirdVariant => videoAssetPathVar3 != null;

  const SignModel({
    required this.id,
    required this.label,
    required this.meaning,
    required this.description,
    this.videoAssetPath,
    this.videoAssetPathVar2,
    this.videoAssetPathVar3,
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