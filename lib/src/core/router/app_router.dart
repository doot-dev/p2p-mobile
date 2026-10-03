import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/shell/home_shell.dart';

abstract class Routes {
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const projects = '/projects';
}

/// App router. Redirects between the auth screens and the authenticated shell
/// based on the Firebase auth state.
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final loggedIn = authState.asData?.value != null;

  // Screens reachable while logged out.
  const authRoutes = {Routes.login, Routes.signup, Routes.forgotPassword};

  return GoRouter(
    initialLocation: Routes.projects,
    redirect: (context, state) {
      final atAuthRoute = authRoutes.contains(state.matchedLocation);
      if (!loggedIn) return atAuthRoute ? null : Routes.login;
      if (atAuthRoute) return Routes.projects;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.projects,
        builder: (context, state) => const HomeShell(),
      ),
    ],
  );
});
