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
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// End-to-end proof of brief P12 item 3's "integration test for the guest → search → detail →
/// call flow", run for real against a Linux desktop build (`flutter test integration_test -d
/// linux`) rather than the plain `flutter_test` binding every other test file in this app
/// uses — this is the one test in the suite that boots the real [App] widget tree, the real
/// `go_router` navigation, and the real `ContactBar`/`url_launcher` call path together, not
/// each in isolation. The backend itself is still faked (same "fake repository" pattern as
/// `map_home_screen_test.dart`/`listing_detail_screen_test.dart`) — a real device/CI runner
/// has no seeded Postgres to talk to, and the point of this test is the *app's* wiring, not
/// re-proving the backend contract those two widget-test files already cover.
class _FakeAuthNotifier extends AuthStateNotifier {
  @override
  AuthState build() => const AuthState.guest();
}

class _NoopAuthRepository extends AuthRepository {
  _NoopAuthRepository(super.ref);

  @override
  Future<void> restoreSession() async {}
}

/// In-memory stand-in for [TokenStorage] — a real Linux build would otherwise reach for a
/// real Secret Service (libsecret) over D-Bus, which a headless CI/dev-container display
/// doesn't have. Same fake `widget_test.dart` uses, needed here because this test runs the
/// real platform channel, not `flutter_test`'s mocked one.
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

class _FakeListingsRepository extends ListingsRepository {
  _FakeListingsRepository(super.ref);

  final events = <(int, ListingEventKind)>[];

  @override
  Future<MapMarkersResult> fetchMapMarkers(MapFilters filters) async =>
      const MapMarkersResult(results: [_marker], truncated: false);

  @override
  Future<Paginated<Listing>> fetchListings(MapFilters filters, {int page = 1}) async =>
      Paginated<Listing>(count: 1, results: [_listing]);

  @override
  Future<Listing> fetchListingDetail(int id) async => _listing;

  @override
  Future<void> postEvent(int listingId, ListingEventKind kind) async {
    events.add((listingId, kind));
  }
}

/// No place matches by default — same reasoning as `map_home_screen_test.dart`'s own fake:
/// a real [GeoRepository] would hit the network for a place the seed data doesn't have.
class _FakeGeoRepository extends GeoRepository {
  _FakeGeoRepository(super.ref);

  @override
  Future<List<PlaceResult>> searchPlaces(String query) async => const [];
}

class _FakeListingDetailRepository extends ListingDetailRepository {
  _FakeListingDetailRepository(super.ref);

  @override
  Future<List<Listing>> fetchSimilar(Listing listing) async => const [];
}

final _owner = User(
  id: 5,
  name: 'محمد العلي',
  role: UserRole.owner,
  phone: '+963987654321',
  createdAt: DateTime.utc(2024, 3, 1),
);

final _listing = Listing(
  id: 101,
  title: 'شقة في حي الحسين',
  purpose: ListingPurpose.sale,
  propertyType: PropertyType.apartment,
  price: '85000.00',
  neighborhoodName: 'حي الحسين',
  imagesCount: 0,
  images: const [],
  description: 'شقة واسعة ومضيئة.',
  owner: _owner,
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'guest searches, opens a listing from the results, and taps call — the call event fires',
    (tester) async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      late _FakeListingsRepository fakeRepo;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(_FakeAuthNotifier.new),
            authRepositoryProvider.overrideWith((ref) => _NoopAuthRepository(ref)),
            tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
            listingsRepositoryProvider.overrideWith((ref) {
              fakeRepo = _FakeListingsRepository(ref);
              return fakeRepo;
            }),
            geoRepositoryProvider.overrideWith((ref) => _FakeGeoRepository(ref)),
            listingDetailRepositoryProvider.overrideWith(
              (ref) => _FakeListingDetailRepository(ref),
            ),
          ],
          child: const App(),
        ),
      );
      await tester.pumpAndSettle();

      // Guest lands on the welcome screen and continues without signing in.
      expect(find.text('متابعة كضيف'), findsOneWidget);
      await tester.tap(find.text('متابعة كضيف'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Search — same interaction `map_home_screen_test.dart` drives, for real this time.
      await tester.enterText(find.byType(TextField), 'حي الحسين');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(fakeRepo.events, isEmpty); // sanity: nothing fired yet from just searching

      // Switch to the list toggle to reach a tappable result card (not bounded pumpAndSettle —
      // `ListingCardSkeleton` pulses forever while a list's own loading flag is true, the same
      // trap `map_home_screen_test.dart` documents for this exact screen).
      await tester.tap(find.text('القائمة'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('شقة في حي الحسين'), findsOneWidget);

      // Open the listing — its own detail fetch + view event.
      await tester.tap(find.text('شقة في حي الحسين'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(fakeRepo.events, contains((101, ListingEventKind.view)));
      expect(find.text('اتصال'), findsOneWidget);

      // Tap call. `ContactBar._call` records the event synchronously before attempting the
      // real `url_launcher` platform call — this machine has no `tel:` handler, so the launch
      // itself is expected to no-op/fail; what this test proves is that the app's own contract
      // (log the contact event) held end-to-end through real navigation and a real widget
      // tree, not a fake one.
      await tester.tap(find.text('اتصال'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(fakeRepo.events, contains((101, ListingEventKind.call)));
    },
  );
}
