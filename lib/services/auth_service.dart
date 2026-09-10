import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_user_model.dart';
import 'progress_storage_keys.dart';

/// Local, offline stand-in for Firebase Auth. Accounts (email ->
/// {password, displayName}) live in SharedPreferences under
/// [_accountsKey]; the active session lives under [_sessionKey].
///
/// This is a ChangeNotifier so [AuthWrapper] in main.dart can listen
/// for sign-in/sign-out the same way it used to listen to
/// FirebaseAuth's authStateChanges() stream.
///
/// NOTE: passwords are stored in plain text in local device storage.
/// That's fine for an offline demo prototype, but this class should
/// not be reused as-is for anything handling real user data.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Lets existing call sites like `AuthService()` (see login_screen.dart,
  /// signup_screen.dart) keep working unchanged — they all get the same
  /// shared singleton instead of a fresh object.
  factory AuthService() => instance;

  static const _accountsKey = 'kk_local_accounts';
  static const _sessionKey = 'kk_local_session';

  LocalUser? _currentUser;
  bool _ready = false;

  LocalUser? get currentUser => _currentUser;

  /// True once the saved session has been loaded from disk. main.dart
  /// shows a splash/loading state until this flips true.
  bool get isReady => _ready;

  /// Call once at app startup (see main.dart) before runApp.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw != null) {
      try {
        _currentUser = LocalUser.fromMap(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        _currentUser = null;
      }
    }
    _ready = true;
    notifyListeners();
  }

  Future<Map<String, dynamic>> _loadAccounts(SharedPreferences prefs) async {
    final raw = prefs.getString(_accountsKey);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAccounts(
    SharedPreferences prefs,
    Map<String, dynamic> accounts,
  ) async {
    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  Future<void> _persistSession(SharedPreferences prefs) async {
    if (_currentUser == null) {
      await prefs.remove(_sessionKey);
    } else {
      await prefs.setString(_sessionKey, jsonEncode(_currentUser!.toMap()));
    }
  }

  String _newUid() {
    final rand = Random();
    return List.generate(16, (_) => rand.nextInt(16).toRadixString(16)).join();
  }

  /// If someone was browsing as bisita/guest and now signs up or logs
  /// into a real account, their guest progress otherwise gets stranded
  /// under the old random guest uid — it's still on disk, but nothing
  /// ever reads that key again. This copies it over to [toUid].
  ///
  /// For signUp, [toUid]'s progress is empty, so the guest's progress
  /// just becomes the account's progress outright. For signIn (an
  /// existing account may already have its own progress from a
  /// previous session), this merges lesson-by-lesson instead of
  /// overwriting, keeping whichever side is further along for each
  /// lesson so neither session's progress gets clobbered.
  Future<void> _migrateGuestProgress(
    SharedPreferences prefs,
    String fromUid,
    String toUid,
  ) async {
    if (fromUid == toUid) return;
    final fromKey = progressPrefsKey(fromUid);
    final toKey = progressPrefsKey(toUid);

    final fromRaw = prefs.getString(fromKey);
    if (fromRaw == null) return; // guest never actually made progress

    Map<String, dynamic> guestProgress;
    try {
      guestProgress = Map<String, dynamic>.from(jsonDecode(fromRaw) as Map);
    } catch (_) {
      return;
    }
    if (guestProgress.isEmpty) return;

    Map<String, dynamic> accountProgress = {};
    final toRaw = prefs.getString(toKey);
    if (toRaw != null) {
      try {
        accountProgress = Map<String, dynamic>.from(jsonDecode(toRaw) as Map);
      } catch (_) {
        // Corrupt existing data — treat as empty rather than abort;
        // the guest's progress below still lands safely either way.
      }
    }

    final merged = Map<String, dynamic>.from(accountProgress);
    for (final entry in guestProgress.entries) {
      final guestLesson = Map<String, dynamic>.from(entry.value as Map);
      final existing = merged[entry.key] as Map<String, dynamic>?;

      if (existing == null) {
        merged[entry.key] = guestLesson;
        continue;
      }

      final existingScore = (existing['score'] as num?)?.toInt() ?? 0;
      final existingTotal = (existing['total'] as num?)?.toInt() ?? 0;
      final guestScore = (guestLesson['score'] as num?)?.toInt() ?? 0;
      final guestTotal = (guestLesson['total'] as num?)?.toInt() ?? 0;
      final existingRatio =
          existingTotal > 0 ? existingScore / existingTotal : -1.0;
      final guestRatio = guestTotal > 0 ? guestScore / guestTotal : -1.0;
      final useGuestScore = guestRatio > existingRatio;

      final mergedSignsViewed = <String>{
        ...List<String>.from(existing['signsViewed'] as List? ?? const []),
        ...List<String>.from(guestLesson['signsViewed'] as List? ?? const []),
      }.toList();

      merged[entry.key] = {
        'unlocked':
            existing['unlocked'] == true || guestLesson['unlocked'] == true,
        'completed':
            existing['completed'] == true || guestLesson['completed'] == true,
        'score': useGuestScore ? guestScore : existingScore,
        'total': useGuestScore ? guestTotal : existingTotal,
        'signsViewed': mergedSignsViewed,
      };
    }

    await prefs.setString(toKey, jsonEncode(merged));
    // The guest identity is discarded right after this, so its
    // now-merged progress would otherwise sit around as dead data.
    await prefs.remove(fromKey);
  }

  Future<String?> signIn(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    final key = email.trim().toLowerCase();
    final account = accounts[key] as Map<String, dynamic>?;

    if (account == null) {
      return 'Walang account na nahanap para sa email na ito.';
    }
    if (account['password'] != password) {
      return 'Maling password. Subukang muli.';
    }

    // Capture the guest/bisita uid (if that's what we currently are)
    // BEFORE switching _currentUser below, so any progress made while
    // browsing as a guest can be merged into the account being signed
    // into.
    final guestUid = _currentUser?.isAnonymous == true ? _currentUser!.uid : null;

    _currentUser = LocalUser(
      uid: account['uid'] as String,
      email: key,
      displayName: account['displayName'] as String?,
      isAnonymous: false,
    );
    if (guestUid != null) {
      await _migrateGuestProgress(prefs, guestUid, _currentUser!.uid);
    }
    await _persistSession(prefs);
    notifyListeners();
    return null;
  }

  Future<String?> signUp(String email, String password) async {
    if (password.length < 6) {
      return 'Masyadong mahina ang password. Gumamit ng hindi bababa sa 6 na karakter.';
    }
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    final key = email.trim().toLowerCase();

    if (accounts.containsKey(key)) {
      return 'May account na gamit ang email na ito.';
    }

    final guestUid = _currentUser?.isAnonymous == true ? _currentUser!.uid : null;

    final uid = _newUid();
    accounts[key] = {'uid': uid, 'password': password, 'displayName': null};
    await _saveAccounts(prefs, accounts);

    _currentUser = LocalUser(uid: uid, email: key, isAnonymous: false);
    if (guestUid != null) {
      await _migrateGuestProgress(prefs, guestUid, uid);
    }
    await _persistSession(prefs);
    notifyListeners();
    return null;
  }

  /// Saves a display name (nickname) for the currently signed-in
  /// user. Call this right after a successful signUp().
  Future<void> updateDisplayName(String name) async {
    final user = _currentUser;
    if (user == null) return;

    _currentUser = user.copyWith(displayName: name);

    final prefs = await SharedPreferences.getInstance();
    if (!user.isAnonymous && user.email != null) {
      final accounts = await _loadAccounts(prefs);
      final account = accounts[user.email] as Map<String, dynamic>?;
      if (account != null) {
        account['displayName'] = name;
        await _saveAccounts(prefs, accounts);
      }
    }
    await _persistSession(prefs);
    notifyListeners();
  }

  Future<String?> continueAsGuest() async {
    _currentUser = LocalUser(uid: _newUid(), isAnonymous: true);
    final prefs = await SharedPreferences.getInstance();
    await _persistSession(prefs);
    notifyListeners();
    return null;
  }

  /// No email actually goes out locally — this just simulates success
  /// so the UI flow (login_screen.dart) behaves the same as before.
  Future<String?> sendPasswordReset(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    final key = email.trim().toLowerCase();
    if (!accounts.containsKey(key)) {
      return 'Walang account na nahanap para sa email na ito.';
    }
    return null;
  }

  Future<void> signOut() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await _persistSession(prefs);
    notifyListeners();
  }
}
