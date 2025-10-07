import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthenticationProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
      print('DEBUG: AuthProvider - Attempting to sign in user: $email');
      _loading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      print('DEBUG: AuthProvider - Sign in successful');
      return true;
    } on FirebaseAuthException catch (e, stackTrace) {
      print('ERROR: AuthProvider - Sign in failed: ${e.code} - ${e.message}');
      print('STACK TRACE: $stackTrace');
      return false;
    } catch (e, stackTrace) {
      print('ERROR: AuthProvider - Unexpected error during sign in: $e');
      print('STACK TRACE: $stackTrace');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> registerWithEmail(String email, String password) async {
    try {
      print('DEBUG: AuthProvider - Attempting to register user: $email');
      _loading = true;
      notifyListeners();
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      print('DEBUG: AuthProvider - Registration successful');
      return true;
    } on FirebaseAuthException catch (e, stackTrace) {
      print(
          'ERROR: AuthProvider - Registration failed: ${e.code} - ${e.message}');
      print('STACK TRACE: $stackTrace');
      return false;
    } catch (e, stackTrace) {
      print('ERROR: AuthProvider - Unexpected error during registration: $e');
      print('STACK TRACE: $stackTrace');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      print('DEBUG: AuthProvider - Signing out user');
      await _auth.signOut();
      print('DEBUG: AuthProvider - Sign out successful');
    } catch (e, stackTrace) {
      print('ERROR: AuthProvider - Sign out failed: $e');
      print('STACK TRACE: $stackTrace');
    }
  }

  void _onAuthStateChanged(User? firebaseUser) {
    if (firebaseUser != null) {
      print('DEBUG: AuthProvider - User authenticated: ${firebaseUser.uid}');
    } else {
      print('DEBUG: AuthProvider - User signed out');
    }
    _user = firebaseUser;
    notifyListeners();
  }
}
