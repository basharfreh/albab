import 'package:albab_core/albab_core.dart';
import 'package:albab_dashboard/app.dart';
import 'package:albab_dashboard/features/admin/data/admin_models.dart';
import 'package:albab_dashboard/features/admin/data/admin_repository.dart';
import 'package:albab_dashboard/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Never touches the network — mirrors `apps/mobile/test/widget_test.dart`'s
/// `_NoopAuthRepository`: tests below fix the starting [AuthState] directly, so the real
/// `restoreSession()` (which calls `/auth/me/`) would only race that.
class _NoopAuthRepository extends AuthRepository {
  _NoopAuthRepository(super.ref);

  @override
  Future<void> restoreSession() async {}
}

/// Fixes [authStateProvider] to a chosen starting state instead of the real notifier's
/// `unknown`.
class _FakeAuthNotifier extends AuthStateNotifier {
  _FakeAuthNotifier(this._initial);
  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

/// In-memory stand-in for [TokenStorage] — widget tests have no real keychain/keystore.
class _FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {}

  @override
  Future<void> saveAccessToken(String access) async {}

  @override
  Future<void> clear() async {}
}

/// Canned data so [HomeScreen]'s mount-time fetch never touches the network.
class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository(super.ref);

  @override
  Future<AdminKpis> fetchKpis() async => const AdminKpis(
    totalUsers: AdminKpi(total: 6, delta30d: 2),
    totalListings: AdminKpi(total: 60, delta30d: 5),
    forSale: AdminKpi(total: 40, delta30d: 3),
    forRent: AdminKpi(total: 20, delta30d: 2),
  );

  @override
  Future<List<VisitsPoint>> fetchVisits({int days = 30}) async => [];

  @override
  Future<List<ByTypeSlice>> fetchByType() async => [];

  @override
  Future<List<Listing>> fetchAdminListings({
    String? status,
    String ordering = '-created_at',
    int pageSize = 20,
  }) async => [];
}

const _fakeAdmin = User(id: 1, name: 'مشرف الباب', role: UserRole.admin, phone: '+963900000001');

void main() {
  overrides(AuthState initialState) => [
    authStateProvider.overrideWith(() => _FakeAuthNotifier(initialState)),
    authRepositoryProvider.overrideWith((ref) => _NoopAuthRepository(ref)),
    tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
    adminRepositoryProvider.overrideWith((ref) => _FakeAdminRepository(ref)),
  ];

  setUp(() {
    // `localeProvider` reads `PrefsStorage` (shared_preferences) on build — same trap P4
    // documented for the `albab_core` example gallery and apps/mobile's own widget_test.
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('an unauthenticated visitor sees the admin login form', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: overrides(const AuthState.guest()), child: const App()),
    );
    await tester.pumpAndSettle();

    expect(find.text('دخول لوحة التحكم'), findsOneWidget);
  });

  testWidgets('an authenticated admin lands on the home screen inside the shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(const AuthState.authenticated(_fakeAdmin)),
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('دخول لوحة التحكم'), findsNothing);
    expect(find.text('إجمالي المستخدمين'), findsOneWidget);
    expect(find.text('أحدث العقارات المضافة'), findsOneWidget);
  });
}
