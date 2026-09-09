import 'package:albab_core/albab_core.dart';
import 'package:albab_mobile/features/account/data/account_repository.dart';
import 'package:albab_mobile/features/account/ui/account_screen.dart';
import 'package:albab_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _FakeAuthNotifier extends AuthStateNotifier {
  _FakeAuthNotifier(this._initial);
  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

class _NoopAuthRepository extends AuthRepository {
  _NoopAuthRepository(super.ref);

  @override
  Future<void> logout() async {}
}

class _FakeAccountRepository extends AccountRepository {
  _FakeAccountRepository(super.ref);

  @override
  Future<AccountCounts> fetchCounts() async => const AccountCounts(myListings: 5, favorites: 8);
}

const _user = User(
  id: 1,
  name: 'سارة أحمد',
  role: UserRole.owner,
  phone: '+963987654321',
  unreadMessages: 2,
  unreadNotifications: 3,
);

Widget _wrap(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: '/account',
    routes: [
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountScreen(),
      ),
      for (final path in [
        '/my-listings',
        '/favorites',
        '/messages',
        '/notifications',
        '/stats',
        '/settings',
        '/login',
        '/register',
      ])
        GoRoute(path: path, builder: (context, state) => Scaffold(body: Text('ROUTE $path'))),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  ProviderContainer buildContainer(AuthState state) {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(() => _FakeAuthNotifier(state)),
        authRepositoryProvider.overrideWith((ref) => _NoopAuthRepository(ref)),
        accountRepositoryProvider.overrideWith((ref) => _FakeAccountRepository(ref)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  testWidgets('a guest sees the sign-in prompt instead of the profile header', (tester) async {
    final container = buildContainer(const AuthState.guest());
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('سجّل الدخول للوصول إلى حسابك'), findsOneWidget);
    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();
    expect(find.text('ROUTE /login'), findsOneWidget);
  });

  testWidgets('an authenticated user sees counts and unread badges, and rows navigate', (
    tester,
  ) async {
    final container = buildContainer(const AuthState.authenticated(_user));
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('سارة أحمد'), findsOneWidget);
    expect(find.text('5'), findsOneWidget); // my listings count
    expect(find.text('8'), findsOneWidget); // favorites count
    expect(find.text('2'), findsOneWidget); // unread messages badge
    expect(find.text('3'), findsOneWidget); // unread notifications badge

    await tester.tap(find.text('عقاراتي'));
    await tester.pumpAndSettle();
    expect(find.text('ROUTE /my-listings'), findsOneWidget);
  });
}
