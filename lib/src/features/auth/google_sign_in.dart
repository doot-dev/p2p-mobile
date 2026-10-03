// Google sign-in (Android / iOS): Google → Firebase Auth → Firebase ID token, which the app sends to
// P2P-backend `POST /api/auth/firebase` for a P2P session. Firebase is only the Google bridge here;
// the session itself is the shared P2P account.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/api.dart';

/// Web (server) OAuth client id — `oauth_client` with `client_type: 3` in google-services.json.
/// google_sign_in v7 needs it so the returned idToken has an audience Firebase accepts.
const _serverClientId = '343691040198-biur37juk5ramu7d4aussoksina31unp.apps.googleusercontent.com';

/// ponytail: mobile only; web would need the Google Identity Services button.
bool get googleSignInSupported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

bool _initialized = false;

/// Firebase ID token for the chosen Google account, or null if the person cancelled.
Future<String?> googleIdToken() async {
  if (!_initialized) {
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }
  try {
    final account = await GoogleSignIn.instance.authenticate(scopeHint: const ['email']);
    final googleToken = account.authentication.idToken;
    if (googleToken == null) throw const ApiException('Google did not return a sign-in token.');
    final cred = await FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(idToken: googleToken));
    return await cred.user?.getIdToken();
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled) return null;
    throw ApiException(e.description ?? 'Google sign-in failed.');
  } on FirebaseAuthException catch (e) {
    throw ApiException(e.message ?? 'Google sign-in failed.');
  }
}

Future<void> googleSignOut() async {
  if (!googleSignInSupported) return;
  try {
    if (_initialized) await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
  } catch (_) {
    // Nothing to sign out of.
  }
}
