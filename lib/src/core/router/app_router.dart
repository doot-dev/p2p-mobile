import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/projects/presentation/projects_screen.dart';

abstract class Routes {
  static const login = '/login';
  static const projects = '/projects';
}

/// App router. Redirects between the login screen and the authenticated shell
/// based on the Firebase auth state.
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final loggedIn = authState.asData?.value != null;

  return GoRouter(
    initialLocation: Routes.projects,
    redirect: (context, state) {
      final atLogin = state.matchedLocation == Routes.login;
      if (!loggedIn) return atLogin ? null : Routes.login;
      if (atLogin) return Routes.projects;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.projects,
        builder: (context, state) => const ProjectsScreen(),
      ),
    ],
  );
});
