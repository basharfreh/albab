import 'package:albab_core/albab_core.dart';
import 'package:albab_mobile/features/account/data/account_repository.dart';
import 'package:albab_mobile/features/account/ui/account_screen.dart';
import 'package:albab_mobile/features/auth/data/auth_repository.dart';
import 'package:albab_mobile/features/discovery/data/map_filters.dart';
import 'package:albab_mobile/features/discovery/ui/filter_screen.dart';
import 'package:albab_mobile/features/map/data/listings_repository.dart';
import 'package:albab_mobile/features/shell/ui/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Brief P12 item 4: "`MediaQuery.textScaler` up to 1.3 without overflow" — every widget/
/// screen below has already had at least one *narrow-width* `RenderFlex` overflow found and
/// fixed somewhere in this project's history (see `docs/PROGRESS.md`'s P11 entries); a larger
/// text scale stresses the exact same fixed-width `Row`s in a different dimension, so these
/// are the highest-risk surfaces to check, not an arbitrary sample.
Widget _scaledUp(Widget child, {Locale locale = const Locale('ar')}) {
  return MaterialApp(
    theme: AppTheme.light(),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, widget) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
      child: widget!,
    ),
    home: Scaffold(body: child),
  );
}

const _listing = Listing(
  id: 1,
  title: 'منزل جميل في حي الحسين مطل على الحديقة',
  neighborhoodName: 'حي الحسين',
  landmark: 'قرب المسجد الكبير',
  price: '85000.00',
  isNegotiable: true,
  areaSqm: '180',
  bedrooms: 3,
  bathrooms: 2,
  imagesCount: 6,
  purpose: ListingPurpose.sale,
  propertyType: PropertyType.house,
);

class _FakeListingsRepository extends ListingsRepository {
  _FakeListingsRepository(super.ref);

  @override
  Future<int> fetchResultsCount(MapFilters filters) async => 125;

  @override
  Future<List<Neighborhood>> fetchNeighborhoods() async => const [
    Neighborhood(
      id: 1,
      nameAr: 'حي الحسين',
      nameEn: 'Al-Hussein',
      slug: 'al-hussein',
      centerLat: '36.37',
      centerLng: '37.52',
    ),
  ];
}

class _FakeAuthNotifier extends AuthStateNotifier {
  _FakeAuthNotifier(this._initial);
  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

class _NoopAuthRepository extends AuthRepository {
  _NoopAuthRepository(super.ref);
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

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('ListingCard (vertical) at 1.3x scale does not overflow', (tester) async {
    await tester.pumpWidget(
      _scaledUp(
        Center(child: SizedBox(width: 320, child: ListingCard(listing: _listing))),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('ListingCard (horizontal/map-peek) at 1.3x scale does not overflow', (tester) async {
    await tester.pumpWidget(
      _scaledUp(
        Center(
          child: SizedBox(
            width: 360,
            child: ListingCard(listing: _listing, layout: ListingCardLayout.horizontal),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('PropertyStatsRow at 1.3x scale does not overflow', (tester) async {
    await tester.pumpWidget(
      _scaledUp(
        const Center(
          child: SizedBox(
            width: 320,
            child: PropertyStatsRow(areaSqm: '180', bedrooms: 3, bathrooms: 2),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('BottomNavBar at 1.3x scale does not overflow its fixed 64px height', (
    tester,
  ) async {
    await tester.pumpWidget(
      _scaledUp(BottomNavBar(currentIndex: 0, onTap: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('FilterScreen at 1.3x scale does not overflow', (tester) async {
    final container = ProviderContainer(
      overrides: [
        listingsRepositoryProvider.overrideWith((ref) => _FakeListingsRepository(ref)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, widget) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: widget!,
          ),
          home: const FilterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('AccountScreen at 1.3x scale does not overflow', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(() => _FakeAuthNotifier(AuthState.authenticated(_user))),
        authRepositoryProvider.overrideWith((ref) => _NoopAuthRepository(ref)),
        accountRepositoryProvider.overrideWith((ref) => _FakeAccountRepository(ref)),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/account',
      routes: [GoRoute(path: '/account', builder: (context, state) => const AccountScreen())],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, widget) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: widget!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
