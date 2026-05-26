import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthenticationProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  AuthenticationProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  bool _loading = false;
  bool get loading => _loading;

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _loading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (_) {
      return false;
    } catch (_) {
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Creates the Firebase Auth account AND saves the user profile to Firestore.
  Future<bool> registerWithEmail(
    String email,
    String password, {
    required String fullName,
  }) async {
    try {
      _loading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid != null) {
        // Save display name on the Auth user object
        await credential.user?.updateDisplayName(fullName);

        // Persist profile data to Firestore
        await _firestore.collection('users').doc(uid).set({
          'fullName': fullName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Fire off a verification email immediately. Errors here shouldn't
        // block account creation — the user can resend from the verify screen.
        try {
          await credential.user?.sendEmailVerification();
        } catch (_) {}
      }

      return true;
    } on FirebaseAuthException catch (_) {
      return false;
    } catch (_) {
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Re-send the verification email for the currently signed-in user.
  Future<bool> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  // Refresh the cached user so emailVerified reflects the latest server state.
  // We also force-refresh the ID token: reload() alone doesn't always push a
  // new event onto userChanges()/authStateChanges(), so the email-verification
  // gate in main.dart can get stuck. getIdToken(true) makes the stream re-emit.
  Future<bool> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
      _user = _auth.currentUser;
      if (_user != null) {
        try {
          await _user!.getIdToken(true);
        } catch (_) {}
      }
      notifyListeners();
      return _user?.emailVerified ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  void _onAuthStateChanged(User? firebaseUser) {
    _user = firebaseUser;
    notifyListeners();
  }
}
