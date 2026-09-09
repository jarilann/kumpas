import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/lesson_model.dart';
import '../models/module_model.dart';
import '../models/user_progress_model.dart';
import 'auth_service.dart';

/// Reads/writes lesson progress locally in SharedPreferences under
/// key 'kk_progress_{uid}', as a JSON map of lessonId -> LessonProgress.
///
/// Locking is per-lesson (see [LessonProgress] docs): completing a
/// lesson's quiz unlocks the next lesson in the flattened
/// module -> lesson sequence.
class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  final Map<String, LessonProgress> _memoryStates = {};
  String? _memoryUid;
  bool _memoryLoaded = false;

  void _ensureMemoryUser() {
    final uid = _uid;
    if (_memoryUid == uid) return;
    _memoryStates.clear();
    _memoryUid = uid;
    _memoryLoaded = false;
  }

  String? get _uid => AuthService.instance.currentUser?.uid;

  String? get _prefsKey {
    final uid = _uid;
    if (uid == null) return null;
    return 'kk_progress_$uid';
  }

  /// Flattens every module's lessons into a single ordered list —
  /// this defines unlock order across module boundaries.
  List<LessonModel> _flattenLessons(List<ModuleModel> modules) {
    return [for (final m in modules) ...m.lessons];
  }

  /// Fetches progress for every lesson across [modules], seeding the
  /// very first lesson as unlocked-by-default the first time this is
  /// called for a user. Returns an empty map if the user isn't
  /// signed in.
  ///
  /// Resilient to a corrupt or missing local cache: if nothing usable
  /// is found in SharedPreferences (e.g. this is the very first run),
  /// this still returns sensible seeded defaults instead of throwing
  /// and leaving a caller's loading spinner stuck forever.
  Future<Map<String, LessonProgress>> getLessonStates(
    List<ModuleModel> modules,
  ) async {
    _ensureMemoryUser();
    final key = _prefsKey;
    if (key == null) return {};

    final uid = _memoryUid;
    final lessons = _flattenLessons(modules);
    if (_memoryLoaded &&
        lessons.every((lesson) => _memoryStates.containsKey(lesson.id))) {
      return {
        for (final lesson in lessons) lesson.id: _memoryStates[lesson.id]!,
      };
    }

    Map<String, dynamic> existing = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw != null) {
        existing = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      }
    } catch (_) {
      // Genuinely nothing available or corrupt local data — fall
      // through with an empty map, which seeds every lesson to its
      // default below.
    }

    _ensureMemoryUser();
    if (_memoryUid != uid) return {};

    final result = <String, LessonProgress>{};
    for (var i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      final raw = existing[lesson.id];
      // Preserve updates made while this read was in flight.
      result[lesson.id] = _memoryStates.putIfAbsent(
        lesson.id,
        () => raw != null
            ? LessonProgress.fromMap(Map<String, dynamic>.from(raw as Map))
            : LessonProgress.initial(unlocked: i == 0),
      );
    }
    _memoryLoaded = true;
    return result;
  }

  /// Rewrites the whole per-user progress map to disk. Progress data
  /// is small (a handful of lessons), so a full rewrite per save is
  /// fine for this prototype's scale.
  Future<void> _persistAll() async {
    final key = _prefsKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final map = {
      for (final entry in _memoryStates.entries) entry.key: entry.value.toMap(),
    };
    await prefs.setString(key, jsonEncode(map));
  }

  Future<void> _saveLesson(String lessonId, LessonProgress progress) async {
    _ensureMemoryUser();
    final key = _prefsKey;
    if (key == null) return;
    // Synchronize sign views, quiz results, and unlocks before awaiting writes.
    _memoryStates[lessonId] = progress;
    try {
      await _persistAll();
    } catch (_) {
      // Best-effort: callers of markSignViewed/submitQuizResult treat
      // saving as fire-and-forget, so a save failure here shouldn't
      // surface as a crash — the user's in-session progress (current
      // sign index, quiz score) still works via local widget state
      // regardless of whether this particular write landed.
    }
  }

  Future<void> markSignViewed(
    String lessonId,
    String signId,
    List<ModuleModel> modules,
  ) async {
    _ensureMemoryUser();
    final uid = _memoryUid;
    if (!_memoryLoaded) {
      await getLessonStates(modules);
    }
    _ensureMemoryUser();
    if (_memoryUid != uid) return;
    final current = _memoryStates[lessonId];
    if (current == null) return;

    if (!current.signsViewed.contains(signId)) {
      final updated = current.copyWith(
        signsViewed: [...current.signsViewed, signId],
      );
      _memoryStates[lessonId] = updated;
      await _saveLesson(lessonId, updated);
    }
  }

  /// Records a quiz attempt for [lessonId]. Returns true if the next
  /// lesson was newly unlocked as a result — callers can use this to
  /// decide whether to show an unlock celebration screen.
  Future<bool> submitQuizResult({
    required String lessonId,
    required int score,
    required int total,
    required List<ModuleModel> modules,
  }) async {
    _ensureMemoryUser();
    final uid = _memoryUid;
    final lessons = _flattenLessons(modules);
    await getLessonStates(modules);
    _ensureMemoryUser();
    if (_memoryUid != uid) return false;
    final current = _memoryStates[lessonId];
    if (current == null) return false;

    final passed = total > 0 && (score / total) >= 0.6;

    await _saveLesson(
      lessonId,
      current.copyWith(
        score: score,
        total: total,
        completed: passed || current.completed,
      ),
    );

    _ensureMemoryUser();
    if (_memoryUid != uid || !passed) return false;

    final idx = lessons.indexWhere((l) => l.id == lessonId);
    if (idx == -1 || idx + 1 >= lessons.length) return false;

    final nextLesson = lessons[idx + 1];
    final nextState = _memoryStates[nextLesson.id];
    if (nextState != null && !nextState.unlocked) {
      await _saveLesson(nextLesson.id, nextState.copyWith(unlocked: true));
      return true;
    }
    return false;
  }

  /// True once every lesson in [module] is completed.
  bool isModuleCompleted(
    ModuleModel module,
    Map<String, LessonProgress> states,
  ) {
    return module.lessons.every((l) => states[l.id]?.completed == true);
  }

  /// A module is "unlocked" (tappable) once its first lesson is
  /// unlocked.
  bool isModuleUnlocked(
    ModuleModel module,
    Map<String, LessonProgress> states,
  ) {
    if (module.lessons.isEmpty) return false;
    return states[module.lessons.first.id]?.unlocked == true;
  }

  /// Fractional progress (0.0–1.0) across a module's lessons, used
  /// for the module-list progress bar. Counts a lesson as "done" if
  /// completed, and gives partial credit for an in-progress lesson
  /// based on its quiz score.
  double moduleProgressFraction(
    ModuleModel module,
    Map<String, LessonProgress> states,
  ) {
    if (module.lessons.isEmpty) return 0;
    var sum = 0.0;
    for (final lesson in module.lessons) {
      final s = states[lesson.id];
      if (s == null) continue;
      if (s.completed) {
        sum += 1;
      } else if (s.total > 0) {
        sum += (s.score / s.total).clamp(0.0, 1.0);
      }
    }
    return (sum / module.lessons.length).clamp(0.0, 1.0);
  }
}
