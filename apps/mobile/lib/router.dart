import 'package:albab_core/albab_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/account/ui/account_screen.dart';
import 'features/add_listing/ui/add_listing_wizard_screen.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/auth/ui/register_screen.dart';
import 'features/auth/ui/splash_screen.dart';
import 'features/auth/ui/verify_screen.dart';
import 'features/auth/ui/welcome_screen.dart';
import 'features/discovery/ui/filter_screen.dart';
import 'features/favorites/ui/favorites_screen.dart';
import 'features/listing_detail/ui/listing_detail_screen.dart';
import 'features/map/ui/map_home_screen.dart';
import 'features/messages/ui/conversation_screen.dart';
import 'features/messages/ui/messages_screen.dart';
import 'features/my_listings/ui/my_listings_screen.dart';
import 'features/notifications/ui/notifications_screen.dart';
import 'features/settings/ui/edit_profile_screen.dart';
import 'features/settings/ui/settings_screen.dart';
import 'features/shell/ui/app_shell.dart';
import 'features/stats/ui/listing_stats_screen.dart';

/// go_router has no native Riverpod integration — `refreshListenable` wants a plain
/// [Listenable], so this bridges [authStateProvider]'s changes to one. Standard glue for
/// riverpod + go_router, not a general-purpose pattern to reuse elsewhere.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (previous, next) => notifyListeners());
  }
}

/// Routes a guest/authenticated user shouldn't stay on once auth state resolves past
/// `unknown` — see the redirect rule below for why `guest` alone does *not* bounce off these
/// (only `authenticated` does; landing on `/welcome` as a guest is normal, expected state).
const _authOnlyPaths = {'/welcome', '/login', '/register', '/verify'};

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  // A cold-start deep link (brief P8 item 5, `https://albab.sy/l/{id}`, aliased below to
  // `/l/:id`) arrives as the router's very first `matchedLocation` — before auth state has
  // resolved past `unknown`, which unconditionally bounces every location to `/` (splash)
  // until `AuthRepository.restoreSession()` finishes. Captured here once and consumed the
  // first time `location == '/'` resolves past `unknown`, so the original target survives
  // the splash detour instead of always landing on `/map`/`/welcome`.
  String? pendingDeepLink;

  return GoRouter(
    // No explicit `initialLocation`: leaving it unset lets go_router read the platform's
    // actual initial route (the OS-delivered deep link URI on a cold start), instead of
    // always forcing `/` and discarding it.
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final location = state.matchedLocation;

      // Splash is where `AuthRepository.restoreSession()` (kicked off by SplashScreen
      // itself) resolves `unknown` into `guest`/`authenticated` — nothing to do until then.
      if (authState is AuthStateUnknown) {
        if (location != '/') {
          pendingDeepLink ??= state.uri.toString();
        }
        return location == '/' ? null : '/';
      }
      if (location == '/') {
        final deepLink = pendingDeepLink;
        if (deepLink != null) {
          pendingDeepLink = null;
          return deepLink;
        }
        // A working stored token skips `/welcome` entirely ("login persists across
        // restart"); no token resolves to `guest`, which lands on `/welcome` and waits for
        // an explicit tap (see WelcomeScreen) — "cold start → guest → map" is two steps.
        return authState is AuthStateAuthenticated ? '/map' : '/welcome';
      }
      if (authState is AuthStateAuthenticated &&
          _authOnlyPaths.contains(location)) {
        return '/map';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(initialPhone: state.extra as String?),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) => ListingDetailScreen(
          listingId: int.parse(state.pathParameters['id']!),
        ),
      ),
      // Deep-link alias (brief UC-19/P8 item 5): `Share` produces `https://albab.sy/l/{id}`,
      // never `/listing/{id}` — kept as a separate, redirect-only path rather than renaming
      // the internal route, since brief §10 forbids renaming anything the brief already
      // named ("/listing/:id" is P6's).
      GoRoute(
        path: '/l/:id',
        redirect: (context, state) => '/listing/${state.pathParameters['id']}',
      ),
      GoRoute(
        path: '/filters',
        builder: (context, state) => const FilterScreen(),
      ),
      // The remaining P10 screens (brief items 2/3/5/6/7) — all pushed from the account
      // screen's row list or (for `/conversation/:id`) from the messages tab/a notification
      // tap, never tabs of their own, so they sit outside the `StatefulShellRoute` like
      // `/filters` and `/listing/:id` already do.
      GoRoute(
        path: '/my-listings',
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) => const ListingStatsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/conversation/:id',
        builder: (context, state) => ConversationScreen(
          conversationId: int.parse(state.pathParameters['id']!),
          conversation: state.extra as Conversation?,
        ),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) {
          final extra = state.extra! as Map<String, dynamic>;
          return VerifyScreen(
            phone: extra['phone'] as String,
            purpose: extra['purpose'] as OtpPurpose,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                builder: (context, state) => const MessagesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/add',
                builder: (context, state) => const AddListingWizardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
