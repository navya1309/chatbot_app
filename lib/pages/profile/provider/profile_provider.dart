import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── State ──
  Map<String, dynamic> _userData = {};
  bool isLoading = false;
  String? error;

  User? get currentUser => _auth.currentUser;
  String get fullName =>
      (_userData['fullName'] as String?)?.trim().isNotEmpty == true
          ? _userData['fullName'] as String
          : currentUser?.displayName ?? 'Friend';
  String get email =>
      (_userData['email'] as String?) ?? currentUser?.email ?? 'Not set';
  DateTime? get memberSince {
    final v = _userData['createdAt'];
    if (v is Timestamp) return v.toDate();
    return null;
  }

  String get initials {
    final n = fullName;
    return n.isNotEmpty ? n[0].toUpperCase() : 'P';
  }

  // ── Load ──

  Future<void> loadProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      _userData = doc.data() ?? {};
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  /// Streams the Firestore document so the profile page updates in real-time.
  Stream<DocumentSnapshot<Map<String, dynamic>>>? get profileStream {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots();
  }

  void onProfileSnapshot(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  // ── Update profile ──

  /// Updates the user's display name in Firestore and on the Firebase Auth
  /// user record. Throws on failure so the UI can show an error.
  Future<void> updateFullName(String newName) async {
    final uid = currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user');
    final trimmed = newName.trim();
    if (trimmed.isEmpty) throw ArgumentError('Name cannot be empty');

    await _firestore
        .collection('users')
        .doc(uid)
        .set({'fullName': trimmed}, SetOptions(merge: true));
    await currentUser?.updateDisplayName(trimmed);

    _userData = {..._userData, 'fullName': trimmed};
    notifyListeners();
  }

  // ── Sign Out ──

  /// Signs out and navigates to the onboarding screen, clearing the entire
  /// back stack so the user cannot press Back to return to the app.
  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
            '/onboarding', (_) => false);
      }
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }
}
