import 'package:albab_core/albab_core.dart';
import 'package:albab_mobile/app.dart';
import 'package:albab_mobile/features/auth/data/auth_repository.dart';
import 'package:albab_mobile/features/discovery/data/geo_repository.dart';
import 'package:albab_mobile/features/discovery/data/map_filters.dart';
import 'package:albab_mobile/features/listing_detail/data/listing_detail_repository.dart';
import 'package:albab_mobile/features/map/data/listings_repository.dart';
import 'package:albab_mobile/features/map/ui/widgets/map_pin.dart';
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

  /// When set, [fetchMapMarkers] throws instead of succeeding — one failure only, then
  /// clears itself, so a test can drive "refetch fails once" without an infinite loop.
  bool failNextMarkerFetch = false;

  /// Per-page results, keyed by page number — only consulted when non-empty, so tests that
  /// only ever set [listings] (single implicit page) keep working unmodified. Every request
  /// for a page in [failListingPages] throws (it keeps failing until the test itself removes
  /// the page, simulating "connectivity restored" — a plain fail-once flag would let an
  /// automatic scroll-triggered retry silently succeed before a test ever gets to assert on
  /// the failed state), so a test can assert a *manual* retry re-requests the same page
  /// rather than skipping past it (brief P12 item 5: "retry on every failed request").
  Map<int, List<Listing>> pagedListings = const {};
  final Set<int> failListingPages = {};
  final requestedListingPages = <int>[];

  @override
  Future<MapMarkersResult> fetchMapMarkers(MapFilters filters) async {
    lastMapFilters = filters;
    if (failNextMarkerFetch) {
      failNextMarkerFetch = false;
      throw const ApiException(kind: ApiErrorKind.network);
    }
    return MapMarkersResult(results: markers, truncated: false);
  }

  @override
  Future<Paginated<Listing>> fetchListings(MapFilters filters, {int page = 1}) async {
    lastListFilters = filters;
    requestedListingPages.add(page);
    if (failListingPages.contains(page)) {
      throw const ApiException(kind: ApiErrorKind.network);
    }
    if (pagedListings.isNotEmpty) {
      return Paginated<Listing>(
        count: pagedListings.values.fold(0, (n, l) => n + l.length),
        results: pagedListings[page] ?? const <Listing>[],
        next: pagedListings.containsKey(page + 1) ? 'page=${page + 1}' : null,
      );
    }
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

  testWidgets(
    'the filter and notifications overlay buttons expose accessible tooltips (brief P12 item 4)',
    (tester) async {
      await tester.pumpWidget(ProviderScope(overrides: overrides(), child: const App()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('متابعة كضيف'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byTooltip('البحث والتصفية'), findsOneWidget);
      expect(find.byTooltip('الإشعارات'), findsOneWidget);
    },
  );

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

  testWidgets(
    'a failed "load more" shows a retry row instead of a permanent spinner, and retrying '
    're-requests the same page rather than skipping it (brief P12 item 5)',
    (tester) async {
      final page1 = [
        for (var i = 1; i <= 20; i++)
          Listing(
            id: i,
            title: 'عقار $i',
            purpose: ListingPurpose.sale,
            propertyType: PropertyType.house,
            price: '10000.00',
          ),
      ];
      final page2 = [
        Listing(
          id: 21,
          title: 'عقار الصفحة الثانية',
          purpose: ListingPurpose.sale,
          propertyType: PropertyType.house,
          price: '10000.00',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(_FakeAuthNotifier.new),
            authRepositoryProvider.overrideWith((ref) => _NoopAuthRepository(ref)),
            listingsRepositoryProvider.overrideWith((ref) {
              final repo = _FakeListingsRepository(ref);
              repo.pagedListings = {1: page1, 2: page2};
              repo.failListingPages.add(2);
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
      expect(find.text('عقار 1'), findsOneWidget);

      // Jump straight to the bottom via the list's own `ScrollController`, not a simulated
      // drag/fling — a fling's own deceleration fires the scroll listener an unpredictable
      // number of times as it settles, which isn't something a test should have to model.
      // Even a plain `jumpTo` fires the listener twice as it settles (a `ScrollPosition`
      // internal — nothing specific to this screen), so one jump means two chained failed
      // attempts, each its own microtask-deferred `await`; a plain `pump()`/`pump(50ms)`
      // pair (the pattern every other test in this file uses) isn't enough real time for
      // both to resolve and the widget tree to reflect the final error state.
      final listController = tester.widget<ListView>(find.byType(ListView)).controller!;
      listController.jumpTo(listController.position.maxScrollExtent);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(fakeRepo.requestedListingPages, [1, 2, 2]); // both attempts asked for page 2
      expect(find.text('تعذر تحميل المزيد، إعادة المحاولة'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing); // not a permanent spinner

      // "Connectivity restored" — now let page 2 succeed, then have the user retry manually.
      fakeRepo.failListingPages.remove(2);
      await tester.tap(find.text('تعذر تحميل المزيد، إعادة المحاولة'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The manual retry re-asked for the exact page that failed (page 2 again), never page 3.
      expect(fakeRepo.requestedListingPages, [1, 2, 2, 2]);
      expect(find.text('عقار الصفحة الثانية'), findsOneWidget);
    },
  );

  testWidgets(
    'a background marker refetch that fails while markers already exist keeps showing them '
    'and offers a retry snackbar instead of going blank (brief P12 item 5)',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(_FakeAuthNotifier.new),
          authRepositoryProvider.overrideWith((ref) => _NoopAuthRepository(ref)),
          listingsRepositoryProvider.overrideWith((ref) {
            final repo = _FakeListingsRepository(ref);
            repo.markers = const [_marker];
            fakeRepo = repo;
            return repo;
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('متابعة كضيف'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(MapPin), findsOneWidget); // the initial fetch succeeded

      fakeRepo.failNextMarkerFetch = true;
      container.read(mapFiltersProvider.notifier).setBbox('1,1,2,2');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(MapPin), findsOneWidget); // still showing the last good markers
      expect(find.text('تعذر تحديث النتائج — يتم عرض آخر نتائج محفوظة'), findsOneWidget);
    },
  );
}
