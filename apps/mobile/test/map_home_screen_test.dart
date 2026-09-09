import 'package:albab_core/albab_core.dart';
import 'package:albab_mobile/app.dart';
import 'package:albab_mobile/features/auth/data/auth_repository.dart';
import 'package:albab_mobile/features/discovery/data/geo_repository.dart';
import 'package:albab_mobile/features/discovery/data/map_filters.dart';
import 'package:albab_mobile/features/listing_detail/data/listing_detail_repository.dart';
import 'package:albab_mobile/features/map/data/listings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _FakeAuthNotifier extends AuthStateNotifier {
  @override
  AuthState build() => const AuthState.guest();
}

class _NoopAuthRepository extends AuthRepository {
  _NoopAuthRepository(super.ref);

  @override
  Future<void> restoreSession() async {}
}

/// Records every call so tests can assert on what P6's screen actually requested, and
/// returns canned data instead of hitting a real backend (widget tests have no network).
class _FakeListingsRepository extends ListingsRepository {
  _FakeListingsRepository(super.ref);

  List<ListingMapMarker> markers = const [];
  List<Listing> listings = const [];
  Listing? detail;
  final events = <(int, ListingEventKind)>[];
  MapFilters? lastMapFilters;
  MapFilters? lastListFilters;

  @override
  Future<MapMarkersResult> fetchMapMarkers(MapFilters filters) async {
    lastMapFilters = filters;
    return MapMarkersResult(results: markers, truncated: false);
  }

  @override
  Future<Paginated<Listing>> fetchListings(MapFilters filters, {int page = 1}) async {
    lastListFilters = filters;
    return Paginated<Listing>(count: listings.length, results: listings);
  }

  @override
  Future<Listing> fetchListingDetail(int id) async {
    final found = detail;
    if (found == null) throw StateError('no detail stubbed');
    return found;
  }

  @override
  Future<void> postEvent(int listingId, ListingEventKind kind) async {
    events.add((listingId, kind));
  }
}

/// No place matches by default, so a search submit falls through to the free-text filter
/// path (brief P7 item 5) — a real [GeoRepository] would otherwise hit the network and
/// leave the submit handler's `Future` unresolved for the widget test's own bounded pumps.
class _FakeGeoRepository extends GeoRepository {
  _FakeGeoRepository(super.ref);

  List<PlaceResult> results = const [];

  @override
  Future<List<PlaceResult>> searchPlaces(String query) async => results;
}

/// P8's [ListingDetailScreen] fetches "similar listings" as soon as its own detail load
/// resolves — this file's own "opening a listing... fires exactly one view event" test
/// reaches that screen, so a real [ListingDetailRepository] would otherwise hit the network
/// same as [_FakeGeoRepository] above.
class _FakeListingDetailRepository extends ListingDetailRepository {
  _FakeListingDetailRepository(super.ref);

  @override
  Future<List<Listing>> fetchSimilar(Listing listing) async => const [];
}

const _listing = Listing(
  id: 101,
  title: 'شقة في حي الحسين',
  purpose: ListingPurpose.sale,
  propertyType: PropertyType.apartment,
  price: '85000.00',
  neighborhoodName: 'حي الحسين',
  imagesCount: 3,
);

const _marker = ListingMapMarker(
  id: 101,
  lat: '36.37',
  lng: '37.51',
  propertyType: PropertyType.apartment,
  purpose: ListingPurpose.sale,
  price: '85000.00',
);

void main() {
  late _FakeListingsRepository fakeRepo;

  // Untyped (inferred) return, matching `widget_test.dart`'s helper — riverpod doesn't
  // export `Override` publicly by name.
  overrides() => [
    authStateProvider.overrideWith(_FakeAuthNotifier.new),
    authRepositoryProvider.overrideWith((ref) => _NoopAuthRepository(ref)),
    listingsRepositoryProvider.overrideWith((ref) {
      fakeRepo = _FakeListingsRepository(ref);
      return fakeRepo;
    }),
    geoRepositoryProvider.overrideWith((ref) => _FakeGeoRepository(ref)),
    listingDetailRepositoryProvider.overrideWith((ref) => _FakeListingDetailRepository(ref)),
  ];

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('map tab requests markers for the initial Al-Bab bbox and shows the toggle bar', (
    tester,
  ) async {
    await tester.pumpWidget(ProviderScope(overrides: overrides(), child: const App()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('متابعة كضيف'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(fakeRepo.lastMapFilters, isNotNull);
    expect(fakeRepo.lastMapFilters!.bbox, isNotNull);
    expect(find.byIcon(Icons.map_outlined), findsWidgets);
    expect(find.byIcon(Icons.list_outlined), findsOneWidget);
  });

  testWidgets('an empty area shows the "no properties" empty state', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: overrides(), child: const App()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('متابعة كضيف'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('لا توجد عقارات في هذه المنطقة'), findsOneWidget);
  });

  testWidgets('switching to the list toggle shows listings from the repository', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(_FakeAuthNotifier.new),
          authRepositoryProvider.overrideWith((ref) => _NoopAuthRepository(ref)),
          listingsRepositoryProvider.overrideWith((ref) {
            final repo = _FakeListingsRepository(ref);
            repo.markers = const [_marker];
            repo.listings = const [_listing];
            fakeRepo = repo;
            return repo;
          }),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('متابعة كضيف'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('القائمة'));
    // Bounded pumps, not `pumpAndSettle`: `ListingCardSkeleton` pulses forever while the
    // list's own loading state is true, which would make `pumpAndSettle` hang (the same
    // trap P4's `PROGRESS.md` entry documented for `LoadingSkeleton`).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(fakeRepo.lastListFilters, isNotNull);
    expect(find.text('شقة في حي الحسين'), findsOneWidget);
  });

  testWidgets('a search submit sets the query filter and refetches markers', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: overrides(), child: const App()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('متابعة كضيف'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextField), 'حي الحسين');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(fakeRepo.lastMapFilters!.query, 'حي الحسين');
  });

  testWidgets(
    'a filter change committed from elsewhere (the filter screen applying) refetches '
    'markers too, not just a map pan or a search submit',
    (tester) async {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('متابعة كضيف'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final requestsBefore = fakeRepo.lastMapFilters;
      expect(requestsBefore, isNotNull);

      // Simulates `FilterScreen._apply()` committing a draft from a different route —
      // nothing here pans the map or submits a search.
      container
          .read(mapFiltersProvider.notifier)
          .apply(requestsBefore!.copyWith(purpose: () => ListingPurpose.sale));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(fakeRepo.lastMapFilters!.purpose, ListingPurpose.sale);
    },
  );

  testWidgets('opening a listing from the list fires exactly one view event', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(_FakeAuthNotifier.new),
          authRepositoryProvider.overrideWith((ref) => _NoopAuthRepository(ref)),
          listingsRepositoryProvider.overrideWith((ref) {
            final repo = _FakeListingsRepository(ref);
            repo.markers = const [_marker];
            repo.listings = const [_listing];
            repo.detail = _listing;
            fakeRepo = repo;
            return repo;
          }),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('متابعة كضيف'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('القائمة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('شقة في حي الحسين'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(fakeRepo.events, [(101, ListingEventKind.view)]);
  });
}
