import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_user_model.dart';

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

    _currentUser = LocalUser(
      uid: account['uid'] as String,
      email: key,
      displayName: account['displayName'] as String?,
      isAnonymous: false,
    );
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

    final uid = _newUid();
    accounts[key] = {'uid': uid, 'password': password, 'displayName': null};
    await _saveAccounts(prefs, accounts);

    _currentUser = LocalUser(uid: uid, email: key, isAnonymous: false);
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
