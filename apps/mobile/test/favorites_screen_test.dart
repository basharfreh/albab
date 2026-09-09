import 'package:albab_core/albab_core.dart';
import 'package:albab_mobile/features/favorites/data/favorites_repository.dart';
import 'package:albab_mobile/features/favorites/ui/favorites_screen.dart';
import 'package:albab_mobile/features/listing_detail/data/listing_detail_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeFavoritesRepository extends FavoritesRepository {
  _FakeFavoritesRepository(super.ref);

  List<Listing> items = const [];

  @override
  Future<List<Listing>> fetchFavorites() async => items;
}

class _FakeListingDetailRepository extends ListingDetailRepository {
  _FakeListingDetailRepository(super.ref);

  final removed = <int>[];

  @override
  Future<void> removeFavorite(int listingId) async {
    removed.add(listingId);
  }
}

Widget _wrap(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: '/favorites',
    routes: [
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) =>
            Scaffold(body: Text('LISTING ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const Scaffold(body: Text('MAP')),
      ),
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
  late _FakeListingDetailRepository detailRepo;

  ProviderContainer buildContainer({List<Listing> favorites = const []}) {
    final container = ProviderContainer(
      overrides: [
        favoritesRepositoryProvider.overrideWith((ref) {
          final repo = _FakeFavoritesRepository(ref)..items = favorites;
          return repo;
        }),
        listingDetailRepositoryProvider.overrideWith((ref) {
          detailRepo = _FakeListingDetailRepository(ref);
          return detailRepo;
        }),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  testWidgets('shows the empty state pointing to the map when there are no favorites', (
    tester,
  ) async {
    final container = buildContainer();
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد عقارات في المفضلة'), findsOneWidget);
    expect(find.text('الخريطة'), findsOneWidget);

    await tester.tap(find.text('الخريطة'));
    await tester.pumpAndSettle();
    expect(find.text('MAP'), findsOneWidget);
  });

  testWidgets('renders a favorited listing and removes it on the favorite toggle', (
    tester,
  ) async {
    final container = buildContainer(
      favorites: [
        const Listing(
          id: 5,
          title: 'فيلا في حي المشلب',
          purpose: ListingPurpose.sale,
          propertyType: PropertyType.house,
          price: '120000.00',
          isFavorited: true,
        ),
      ],
    );
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('فيلا في حي المشلب'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();

    expect(detailRepo.removed, [5]);
    expect(find.text('فيلا في حي المشلب'), findsNothing);
    expect(find.text('تمت الإزالة من المفضلة'), findsOneWidget);
  });
}
