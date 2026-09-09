import 'package:albab_core/albab_core.dart';
import 'package:albab_mobile/app.dart';
import 'package:albab_mobile/features/auth/data/auth_repository.dart';
import 'package:albab_mobile/features/listing_detail/data/listing_detail_repository.dart';
import 'package:albab_mobile/features/map/data/listings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _NoopAuthRepository extends AuthRepository {
  _NoopAuthRepository(super.ref);

  @override
  Future<void> restoreSession() async {}
}

class _FakeListingsRepository extends ListingsRepository {
  _FakeListingsRepository(super.ref);

  @override
  Future<Listing> fetchListingDetail(int id) async => Listing(
    id: id,
    title: 'عقار تجريبي',
    purpose: ListingPurpose.sale,
    propertyType: PropertyType.house,
  );

  @override
  Future<void> postEvent(int listingId, ListingEventKind kind) async {}
}

class _FakeListingDetailRepository extends ListingDetailRepository {
  _FakeListingDetailRepository(super.ref);

  @override
  Future<List<Listing>> fetchSimilar(Listing listing) async => const [];
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  testWidgets(
    'a cold-start deep link to /l/:id survives the splash/auth-resolution detour and opens '
    'the listing (brief P8 item 5, UC-19)',
    (tester) async {
      tester.platformDispatcher.defaultRouteNameTestValue = '/l/101';
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => _NoopAuthRepository(ref)),
          listingsRepositoryProvider.overrideWith((ref) => _FakeListingsRepository(ref)),
          listingDetailRepositoryProvider.overrideWith(
            (ref) => _FakeListingDetailRepository(ref),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
      await tester.pump(); // the splash frame — authState is still `unknown` here

      // Mirrors what `AuthRepository.restoreSession()` would eventually do; this test
      // isolates the router's deep-link preservation from session restoration itself.
      container.read(authStateProvider.notifier).setGuest();
      await tester.pumpAndSettle();

      expect(find.text('عقار تجريبي'), findsOneWidget);
      expect(find.text('متابعة كضيف'), findsNothing); // never landed on /welcome
    },
  );
}
