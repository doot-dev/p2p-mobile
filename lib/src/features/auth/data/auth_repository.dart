import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_status.dart';

/// Web (server) OAuth client id — `oauth_client` with `client_type: 3` in
/// `android/app/google-services.json`. google_sign_in v7 needs this so the
/// returned `idToken` has an audience Firebase accepts. It is project-level, so
/// the same value is used for both the dev and prod flavors.
const _googleServerClientId =
    '343691040198-biur37juk5ramu7d4aussoksina31unp.apps.googleusercontent.com';

/// Wraps Firebase Auth (email/password + Google). The DB profile is created
/// separately via the REST API after first sign-in (mirrors the web app's
/// `ensureUserProfile` server action).
class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (displayName != null && displayName.isNotEmpty) {
      await credential.user?.updateDisplayName(displayName);
    }
    return credential;
  }

  /// google_sign_in v7 requires a one-time [GoogleSignIn.initialize] call.
  static bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
    _googleInitialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'invalid-credential',
          message: 'Google did not return an ID token.',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      // Map a user cancel to the silent 'cancelled' code; rethrow the rest.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw FirebaseAuthException(code: 'cancelled');
      }
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() async {
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }

  /// Maps Firebase error codes to friendly copy (mirrors `getAuthErrorMessage`).
  static String messageForCode(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'cancelled':
        return '';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());

/// Emits the current Firebase user (or null). Drives router redirects.
/// Falls back to a null stream until Firebase has been configured.
final authStateProvider = StreamProvider<User?>((ref) {
  if (!AppStatus.firebaseReady) return Stream<User?>.value(null);
  return ref.watch(authRepositoryProvider).authStateChanges();
});
