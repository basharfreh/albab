import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/ui/login_screen.dart';
import 'features/auth/ui/splash_screen.dart';
import 'features/home/ui/home_screen.dart';
import 'features/listings/ui/listings_screen.dart';
import 'features/reports/ui/reports_screen.dart';
import 'features/settings/ui/settings_screen.dart';
import 'features/shell/ui/coming_soon_screen.dart';
import 'features/shell/ui/dashboard_shell.dart';
import 'features/users/ui/users_screen.dart';

/// Bridges [authStateProvider] to a plain [Listenable] for go_router's `refreshListenable` —
/// same glue apps/mobile's router uses.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (previous, next) => notifyListeners());
  }
}

const _authOnlyPaths = {'/', '/login'};

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final location = state.matchedLocation;

      // `/` (SplashScreen) is where `AuthRepository.restoreSession()` resolves `unknown`
      // into `guest`/`authenticated` — nothing to do until then.
      if (authState is AuthStateUnknown) {
        return location == '/' ? null : '/';
      }
      final isAdmin = authState is AuthStateAuthenticated;
      if (!isAdmin) {
        return location == '/login' ? null : '/login';
      }
      if (_authOnlyPaths.contains(location)) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/listings', builder: (context, state) => const ListingsScreen()),
          GoRoute(path: '/users', builder: (context, state) => const UsersScreen()),
          GoRoute(
            path: '/promotions',
            builder: (context, state) => const _ComingSoonRoute(path: '/promotions'),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const _ComingSoonRoute(path: '/transactions'),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const _ComingSoonRoute(path: '/notifications'),
          ),
          GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

/// Resolves a sidebar path to its own nav label (rather than the raw path) for
/// [ComingSoonScreen]'s title — kept next to the router so route paths and labels never
/// drift apart.
class _ComingSoonRoute extends ConsumerWidget {
  const _ComingSoonRoute({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final title = switch (path) {
      '/promotions' => l10n.dashNavPromotions,
      '/transactions' => l10n.dashNavTransactions,
      '/notifications' => l10n.dashNavNotifications,
      _ => path,
    };
    return ComingSoonScreen(title: title);
  }
}
