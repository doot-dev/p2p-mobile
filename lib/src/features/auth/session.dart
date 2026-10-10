import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/data.dart';
import '../../core/format.dart';
import '../../core/local_db.dart';
import '../../core/push.dart';
import '../../core/realtime.dart';

/// The shared P2P account (one login across all P2P apps), from /api/auth.
class Account {
  const Account({required this.id, required this.email, required this.name, required this.emailVerified, this.hasPassword = true});

  factory Account.fromJson(Json json) => Account(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String? ?? '',
        emailVerified: json['emailVerified'] == true,
        hasPassword: json['hasPassword'] != false,
      );

  final String id;
  final String email;
  final String name;
  final bool emailVerified;

  /// False for accounts imported without a password (they set one with "Forgot password").
  final bool hasPassword;
}

enum SessionStatus { loading, unreachable, signedOut, signedIn }

class Session {
  const Session(this.status, {this.account, this.profile, this.needsOnboarding = false, this.missing = const []});

  final SessionStatus status;
  final Account? account;

  /// The Pitch To Picture profile (UserProfile, camelCase as the API returns it). The backend creates
  /// it on the first signed-in call, so a signed-in session always has one.
  final Json? profile;

  /// From the server: onboarding not finished, or required details (phone, city, state, country) still missing,
  /// e.g. someone who signed up through Universe with only the basics.
  final bool needsOnboarding;
  final List<String> missing;

  bool get signedIn => status == SessionStatus.signedIn;
  bool get onboarded => !needsOnboarding;

  /// PTPC id, e.g. "PTPC4821".
  String? get ptpcId => profile?['id'] as String?;
}

/// Who is signed in, and how far through sign-up they are. The router guards on this.
class SessionController extends Notifier<Session> {
  ApiClient get _api => ref.read(apiClientProvider);
  TokenStore get _tokens => ref.read(tokenStoreProvider);

  @override
  Session build() {
    _api.onSessionExpired = _expire;
    Future.microtask(bootstrap);
    return const Session(SessionStatus.loading);
  }

  Future<void> bootstrap() async {
    state = const Session(SessionStatus.loading);
    await _tokens.load();
    if (_tokens.refresh == null) {
      state = const Session(SessionStatus.signedOut);
      return;
    }
    await reload();
  }

  /// Re-reads the account and the PTP profile from the server.
  Future<void> reload() async {
    try {
      final me = await _api.get('/api/auth/me') as Json;
      final ptpMe = await _api.get('$ptp/me') as Json;
      final account = Account.fromJson(me['account'] as Json);
      state = Session(
        SessionStatus.signedIn,
        account: account,
        profile: ptpMe['profile'] as Json?,
        needsOnboarding: ptpMe['needsOnboarding'] == true,
        missing: strList(ptpMe['missing']),
      );
      unawaited(Push.register(_api));
      ref.read(realtimeProvider).start(account.id); // live chat + application updates
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _tokens.clear();
        state = const Session(SessionStatus.signedOut);
      } else if (e.statusCode == 403) {
        // Disabled by the Pitch To Picture team.
        await _endLocalSession();
        state = const Session(SessionStatus.signedOut);
        rethrow;
      } else {
        state = const Session(SessionStatus.unreachable);
      }
    }
  }

  /// Replace the cached profile after an edit (PATCH /me returns it).
  /// After a successful save the server has accepted every required field (it refuses otherwise).
  void setProfile(Json profile) =>
      state = Session(state.status, account: state.account, profile: profile, needsOnboarding: profile['onboardingCompleted'] != true);

  Future<void> _startSession(String path, Map<String, String> body) async {
    final res = await _api.post(path, body) as Json;
    await _tokens.save(res['accessToken'] as String, res['refreshToken'] as String);
    await reload();
  }

  Future<void> login(String email, String password) =>
      _startSession('/api/auth/login', {'email': email.trim().toLowerCase(), 'password': password});

  Future<void> register({required String name, required String email, required String password}) =>
      _startSession('/api/auth/register', {'name': name.trim(), 'email': email.trim().toLowerCase(), 'password': password});

  Future<void> requestVerificationCode() => _api.post('/api/auth/verify-email/request');

  Future<void> confirmEmail(String code) async {
    await _api.post('/api/auth/verify-email/confirm', {'code': code});
    await reload();
  }

  Future<void> forgotPassword(String email) => _api.post('/api/auth/forgot-password', {'email': email.trim().toLowerCase()});

  /// PATCH /me — any subset of the profile fields; returns the updated profile.
  Future<void> saveProfile(Json body) async => setProfile((await _api.patch('$ptp/me', body) as Json)['profile'] as Json);

  /// Shared-account password change; other devices are signed out, this one gets fresh tokens.
  Future<void> changePassword(String current, String next) async {
    final res = await _api.post('/api/auth/change-password', {'currentPassword': current, 'newPassword': next}) as Json;
    await _tokens.save(res['accessToken'] as String, res['refreshToken'] as String);
  }

  /// Delete the shared P2P account everywhere (password, or "DELETE" for accounts without one).
  Future<void> deleteAccount({String? password}) async {
    await _api.post('/api/auth/delete-account', password == null ? {'confirm': 'DELETE'} : {'password': password});
    await _endLocalSession();
    state = const Session(SessionStatus.signedOut);
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout', {if (Push.token != null) 'fcmToken': Push.token});
    } on ApiException {
      // Best effort: the local session ends regardless.
    }
    await _endLocalSession();
    state = const Session(SessionStatus.signedOut);
  }

  void _expire() {
    unawaited(_endLocalSession());
    state = const Session(SessionStatus.signedOut);
  }

  /// Close the socket and wipe this device's copy of chats and screens (someone else may sign in next).
  Future<void> _endLocalSession() async {
    await ref.read(realtimeProvider).stop();
    await _tokens.clear();
    await ref.read(localDbProvider).clearAll().catchError((_) {});
  }
}

final sessionProvider = NotifierProvider<SessionController, Session>(SessionController.new);
