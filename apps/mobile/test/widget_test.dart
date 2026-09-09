import 'package:albab_core/albab_core.dart';
import 'package:albab_mobile/app.dart';
import 'package:albab_mobile/features/account/data/account_repository.dart';
import 'package:albab_mobile/features/auth/data/auth_repository.dart';
import 'package:albab_mobile/features/shell/ui/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// P10's account screen fetches row counts on mount — faked here so this test never touches
/// the network, same reasoning P8 documented for `map_home_screen_test.dart`'s own
/// `_FakeListingDetailRepository` override.
class _FakeAccountRepository extends AccountRepository {
  _FakeAccountRepository(super.ref);

  @override
  Future<AccountCounts> fetchCounts() async => const AccountCounts(myListings: 3, favorites: 2);
}

/// Fixes [authStateProvider] to a chosen starting state instead of the real notifier's
/// `unknown` — lets a test skip straight past `AuthRepository.restoreSession()` (which needs
/// a real backend) to exercise the router/shell logic that reacts to `guest`/`authenticated`.
class _FakeAuthNotifier extends AuthStateNotifier {
  _FakeAuthNotifier(this._initial);
  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

/// In-memory stand-in for [TokenStorage] — widget tests have no real keychain/keystore.
class _FakeTokenStorage extends TokenStorage {
  String? _access;
  String? _refresh;

  @override
  Future<String?> readAccessToken() async => _access;

  @override
  Future<String?> readRefreshToken() async => _refresh;

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
  }

  @override
  Future<void> saveAccessToken(String access) async => _access = access;

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}

/// Never touches the network — the tests below set the starting [AuthState] directly via
/// [_FakeAuthNotifier], so the real `restoreSession()` (which calls `/auth/me/`) would only
/// race that and flip the state back to `guest` once its `DioException` resolves.
class _NoopAuthRepository extends AuthRepository {
  _NoopAuthRepository(super.ref);

  @override
  Future<void> restoreSession() async {}
}

const _fakeUser = User(id: 1, name: 'سارة أحمد', role: UserRole.owner, phone: '+963987654321');

void main() {
  // Local (not top-level) so its inferred return type doesn't need to spell out `Override`,
  // which riverpod doesn't export publicly by name.
  overrides(AuthState initialState) => [
    authStateProvider.overrideWith(() => _FakeAuthNotifier(initialState)),
    authRepositoryProvider.overrideWith((ref) => _NoopAuthRepository(ref)),
    tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
    accountRepositoryProvider.overrideWith((ref) => _FakeAccountRepository(ref)),
  ];

  setUp(() {
    // `localeProvider` reads `PrefsStorage` (shared_preferences) on build — fake the
    // platform in-memory, same trap P4 documented for the `albab_core` example gallery.
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('cold start as guest lands on welcome; continuing as guest opens the map shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(overrides: overrides(const AuthState.guest()), child: const App()),
    );
    await tester.pumpAndSettle();

    expect(find.text('متابعة كضيف'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('إنشاء حساب'), findsOneWidget);

    await tester.tap(find.text('متابعة كضيف'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavBar), findsOneWidget);
    expect(find.text('الرئيسية'), findsWidgets);
  });

  testWidgets('a guest tapping a gated tab sees the sign-in sheet, not the tab', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: overrides(const AuthState.guest()), child: const App()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('متابعة كضيف'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    expect(find.text('سجّل الدخول للمتابعة'), findsOneWidget);

    // Dismissing the sheet leaves the map tab selected — it was never switched away from.
    await tester.tapAt(const Offset(200, 50));
    await tester.pumpAndSettle();
    expect(find.text('سجّل الدخول للمتابعة'), findsNothing);
    final navBar = tester.widget<BottomNavBar>(find.byType(BottomNavBar));
    expect(navBar.currentIndex, 0);
  });

  testWidgets('a restored session skips welcome entirely and lands on map', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(const AuthState.authenticated(_fakeUser)),
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('متابعة كضيف'), findsNothing);
    expect(find.byType(BottomNavBar), findsOneWidget);
  });

  testWidgets('logging out from account returns to welcome', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(const AuthState.authenticated(_fakeUser)),
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('سارة أحمد'), findsOneWidget);

    // P10's full account row list (my listings/favorites/messages/notifications/stats/
    // settings) pushes "تسجيل الخروج" below the fold on the test surface's default size.
    await tester.scrollUntilVisible(find.text('تسجيل الخروج'), 200);
    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();

    expect(find.text('متابعة كضيف'), findsOneWidget);
  });
}
