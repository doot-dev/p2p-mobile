// Google sign-in: Google account → Firebase Auth → Firebase ID token → POST /api/auth/firebase → P2P session.
// Firebase only vouches for the Google identity; the P2P backend owns the account and the session.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../firebase_options.dart';

/// Web OAuth client of the Firebase Google provider. Android needs it to receive an ID token.
const _webClientId = '343691040198-biur37juk5ramu7d4aussoksina31unp.apps.googleusercontent.com';
bool _initialized = false;

/// A Firebase ID token for the Google account the user picks, or null if they cancelled.
Future<String?> googleFirebaseIdToken() async {
  final auth = FirebaseAuth.instance;
  final UserCredential cred;
  if (kIsWeb) {
    try {
      cred = await auth.signInWithPopup(GoogleAuthProvider());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request') return null;
      rethrow;
    }
  } else {
    if (!_initialized) {
      await GoogleSignIn.instance.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS ? DefaultFirebaseOptions.ios.iosClientId : null,
        serverClientId: _webClientId,
      );
      _initialized = true;
    }
    try {
      final account = await GoogleSignIn.instance.authenticate();
      cred = await auth.signInWithCredential(GoogleAuthProvider.credential(idToken: account.authentication.idToken));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }
  final token = await cred.user?.getIdToken();
  await auth.signOut(); // the P2P session takes over from here
  return token;
}

/// Forget the Google account on sign-out so the account picker shows next time.
Future<void> googleSignOut() async {
  if (!kIsWeb && _initialized) await GoogleSignIn.instance.signOut();
}
