import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/lesson_model.dart';
import '../models/module_model.dart';
import '../models/user_progress_model.dart';

/// Reads/writes lesson progress in Firestore under:
///   users/{uid}/lessonProgress/{lessonId}
///
/// Locking is per-lesson (see [LessonProgress] docs): completing a
/// lesson's quiz unlocks the next lesson in the flattened
/// module -> lesson sequence.
class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('lessonProgress');
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
  /// Resilient to being offline: Firestore's default .get() already
  /// falls back to the local cache when the server is unreachable
  /// (see the persistenceEnabled setting in main.dart), but if
  /// there's no cache yet either (e.g. this device has never synced
  /// this user's progress), this still returns sensible seeded
  /// defaults instead of throwing and leaving a caller's loading
  /// spinner stuck forever.
  Future<Map<String, LessonProgress>> getLessonStates(
    List<ModuleModel> modules,
  ) async {
    _ensureMemoryUser();
    final collection = _collection;
    if (collection == null) return {};

    final uid = _memoryUid;
    final lessons = _flattenLessons(modules);
    if (_memoryLoaded &&
        lessons.every((lesson) => _memoryStates.containsKey(lesson.id))) {
      return {for (final lesson in lessons) lesson.id: _memoryStates[lesson.id]!};
    }
    Map<String, dynamic> existing = {};
    try {
      final snapshot = await collection.get();
      existing = {for (final doc in snapshot.docs) doc.id: doc.data()};
    } catch (_) {
      try {
        // Explicitly ask for cache-only, in case the plain .get()
        // above failed for a reason other than "offline with no
        // cache" (e.g. it hung waiting on the server rather than
        // falling back automatically).
        final cached = await collection.get(const GetOptions(source: Source.cache));
        existing = {for (final doc in cached.docs) doc.id: doc.data()};
      } catch (_) {
        // Genuinely nothing available (offline + never synced on
        // this device) — fall through with an empty map, which
        // seeds every lesson to its default below.
      }
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
            ? LessonProgress.fromMap(raw)
            : LessonProgress.initial(unlocked: i == 0),
      );
    }
    _memoryLoaded = true;
    return result;
  }

  Future<void> _saveLesson(String lessonId, LessonProgress progress) async {
    _ensureMemoryUser();
    final collection = _collection;
    if (collection == null) return;
    // Synchronize sign views, quiz results, and unlocks before awaiting writes.
    _memoryStates[lessonId] = progress;
    try {
      // With persistence enabled, this resolves as soon as the write
      // lands in the local cache — it does not wait for the server —
      // so this completes quickly even offline, and syncs to
      // Firestore automatically once connectivity returns.
      await collection.doc(lessonId).set(progress.toMap());
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