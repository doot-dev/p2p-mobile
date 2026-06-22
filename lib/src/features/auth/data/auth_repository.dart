import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_status.dart';

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
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
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
