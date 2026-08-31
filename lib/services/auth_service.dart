import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapErrorMessage(e.code);
    }
  }

  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapErrorMessage(e.code);
    }
  }

  /// Saves a display name (nickname) to the currently signed-in user's
  /// Firebase profile. Call this right after a successful signUp().
  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  Future<String?> continueAsGuest() async {
    try {
      await _auth.signInAnonymously();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapErrorMessage(e.code);
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapErrorMessage(e.code);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _mapErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Walang account na nahanap para sa email na ito.';
      case 'wrong-password':
        return 'Maling password. Subukang muli.';
      case 'email-already-in-use':
        return 'May account na gamit ang email na ito.';
      case 'invalid-email':
        return 'Hindi wastong email address.';
      case 'weak-password':
        return 'Masyadong mahina ang password. Gumamit ng hindi bababa sa 6 na karakter.';
      default:
        return 'May naganap na error. Subukang muli.';
    }
  }
}