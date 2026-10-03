import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/profile_repository.dart';
import '../data/auth_repository.dart';

/// Orchestrates the full sign-in flows: Firebase Auth + DB profile bootstrap.
///
/// Screens keep their own loading state and catch `FirebaseAuthException`; these
/// methods rethrow Firebase errors so that UX stays unchanged. The profile
/// bootstrap (`/api/v1/me/ensure`) is best-effort — a backend hiccup must not
/// block authentication, and it is retried whenever the app reloads `me`.
class AuthController {
  AuthController(this._auth, this._profiles);

  final AuthRepository _auth;
  final ProfileRepository _profiles;

  Future<void> _ensureProfile({String? name, String? photoURL}) async {
    try {
      await _profiles.ensureProfile(name: name, photoURL: photoURL);
    } catch (e) {
      debugPrint('⚠️  ensureProfile failed (will retry on next load): $e');
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmail(email, password);
    await _ensureProfile();
  }

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signUpWithEmail(
      email,
      password,
      displayName: name,
    );
    await _ensureProfile(name: name, photoURL: credential.user?.photoURL);
  }

  Future<void> signInWithGoogle() async {
    final credential = await _auth.signInWithGoogle();
    await _ensureProfile(
      name: credential.user?.displayName,
      photoURL: credential.user?.photoURL,
    );
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordReset(email);
}

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(profileRepositoryProvider),
  ),
);
