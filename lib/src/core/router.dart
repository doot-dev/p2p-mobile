import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screens.dart';
import '../features/auth/session.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/inbox/chat_screen.dart';
import '../features/info/info_screens.dart';
import '../features/people/profile_screens.dart';
import '../features/projects/hiring_editor_screen.dart';
import '../features/projects/new_project_screen.dart';
import '../features/projects/pitch_guide_screen.dart';
import '../features/projects/project_screen.dart';
import '../features/shell.dart';
import 'push.dart';

abstract class Routes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';
  static const onboarding = '/onboarding';
  static const home = '/home';
}

const _authPages = {Routes.login, Routes.signup, Routes.forgotPassword};
const _gates = {Routes.splash, ..._authPages, Routes.verifyEmail, Routes.onboarding};

/// Pages anyone can browse without an account, like the website (projects, creators, profiles, info).
bool isBrowsable(String location) =>
    const {Routes.home, '/projects', '/creators', '/contact', '/show'}.contains(location) ||
    (location.startsWith('/project/') && location != '/project/new' && !location.endsWith('/hiring') && !location.endsWith('/pitch-guide')) ||
    location.startsWith('/profile/') ||
    location.startsWith('/legal/');

/// Where the user must be given their session. Null = stay. Pure, so it's unit-tested.
///   loading/unreachable → splash · signed out → Home first; browsable pages + login/signup/forgot (else login)
///   unverified email → verify · profile not completed → onboarding · otherwise anywhere (gates → home)
String? redirectFor(Session session, String location) {
  if (location.startsWith('/legal/')) return null;
  final target = switch (session.status) {
    SessionStatus.loading || SessionStatus.unreachable => Routes.splash,
    // Guests start on Home, like the website.
    SessionStatus.signedOut when location == Routes.splash => Routes.home,
    SessionStatus.signedOut => _authPages.contains(location) || isBrowsable(location) ? location : Routes.login,
    SessionStatus.signedIn when !session.account!.emailVerified => Routes.verifyEmail,
    SessionStatus.signedIn when !session.onboarded => Routes.onboarding,
    SessionStatus.signedIn => _gates.contains(location) ? Routes.home : location,
  };
  return target == location ? null : target;
}

GoRoute _r(String path, Widget Function(GoRouterState s) build) => GoRoute(path: path, builder: (_, s) => build(s));

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects whenever the session changes, without rebuilding the router.
  final refresh = ValueNotifier(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => redirectFor(ref.read(sessionProvider), state.matchedLocation),
    routes: [
      _r(Routes.splash, (_) => const SplashScreen()),
      _r(Routes.login, (_) => const LoginScreen()),
      _r(Routes.signup, (_) => const SignupScreen()),
      _r(Routes.forgotPassword, (_) => const ForgotPasswordScreen()),
      _r(Routes.verifyEmail, (_) => const VerifyEmailScreen()),
      _r(Routes.onboarding, (_) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [for (final tab in tabs) StatefulShellBranch(routes: [GoRoute(path: tab.path, builder: (_, _) => tab.screen)])],
      ),
      _r('/project/new', (_) => const NewProjectScreen()),
      _r('/project/:id', (s) => ProjectScreen(s.pathParameters['id']!)),
      _r('/project/:id/hiring', (s) => HiringEditorScreen(s.pathParameters['id']!)),
      _r('/project/:id/pitch-guide', (s) => PitchGuideScreen(s.pathParameters['id']!)),
      _r('/dashboard', (s) => DashboardScreen(tab: s.uri.queryParameters['tab'])),
      _r('/chat/:uid', (s) => ChatScreen(s.pathParameters['uid']!)),
      _r('/profile/:id', (s) => PublicProfileScreen(s.pathParameters['id']!)),
      _r('/edit-profile', (_) => const EditProfileScreen()),
      _r('/settings', (_) => const SettingsScreen()),
      _r('/legal/:kind', (s) => LegalScreen(s.pathParameters['kind']!)),
      _r('/contact', (_) => const ContactScreen()),
      _r('/show', (_) => const ShowScreen()),
    ],
  );
  Push.listenForTaps(router.push);
  return router;
});
