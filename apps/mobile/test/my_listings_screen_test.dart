import 'package:albab_core/albab_core.dart';
import 'package:albab_mobile/features/my_listings/data/my_listings_repository.dart';
import 'package:albab_mobile/features/my_listings/ui/my_listings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Same "record what was requested, return canned data" pattern every prior mobile test file
/// uses — see `map_home_screen_test.dart`'s `_FakeListingsRepository`.
class _FakeMyListingsRepository extends MyListingsRepository {
  _FakeMyListingsRepository(super.ref);

  List<Listing> published = const [];
  List<Listing> rejected = const [];
  final statusChanges = <(int, String)>[];
  final deletes = <int>[];

  @override
  Future<Paginated<Listing>> fetchMyListings({String? status, int page = 1}) async {
    final results = switch (status) {
      'published' => published,
      'rejected' => rejected,
      _ => [...published, ...rejected],
    };
    return Paginated<Listing>(count: results.length, results: results);
  }

  @override
  Future<List<Listing>> fetchByStatuses(List<String> statuses) async => const [];

  @override
  Future<void> setStatus(int listingId, String status) async {
    statusChanges.add((listingId, status));
  }

  @override
  Future<void> deleteListing(int listingId) async {
    deletes.add(listingId);
  }
}

Widget _wrap(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: '/my-listings',
    routes: [
      GoRoute(
        path: '/my-listings',
        builder: (context, state) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) =>
            Scaffold(body: Text('LISTING ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) => const Scaffold(body: Text('ADD')),
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
  late _FakeMyListingsRepository repo;
  late ProviderContainer container;

  ProviderContainer buildContainer({
    List<Listing> published = const [],
    List<Listing> rejected = const [],
  }) {
    final container = ProviderContainer(
      overrides: [
        myListingsRepositoryProvider.overrideWith((ref) {
          repo = _FakeMyListingsRepository(ref)
            ..published = published
            ..rejected = rejected;
          return repo;
        }),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('the published tab shows a status chip and the row views count', (tester) async {
    container = buildContainer(
      published: [
        Listing(
          id: 1,
          title: 'منزل في حي الحسين',
          purpose: ListingPurpose.sale,
          propertyType: PropertyType.house,
          price: '85000.00',
          status: ListingStatus.published,
          viewsCount: 42,
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('منشور').last); // the "منشور" tab
    await tester.pumpAndSettle();

    expect(find.text('منزل في حي الحسين'), findsOneWidget);
    expect(find.text('42 مشاهدة'), findsOneWidget);
  });

  testWidgets('a rejected listing shows the rejection reason inline', (tester) async {
    container = buildContainer(
      rejected: [
        Listing(
          id: 2,
          title: 'شقة في حي الزهراء',
          purpose: ListingPurpose.rent,
          propertyType: PropertyType.apartment,
          price: '400.00',
          status: ListingStatus.rejected,
          rejectionReason: 'صور غير واضحة',
          createdAt: DateTime(2026, 1, 2),
        ),
      ],
    );

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مرفوض').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('صور غير واضحة'), findsOneWidget);
  });

  testWidgets('deleting a listing asks for confirmation, then removes the row', (tester) async {
    container = buildContainer(
      published: [
        Listing(
          id: 3,
          title: 'أرض للبيع',
          purpose: ListingPurpose.sale,
          propertyType: PropertyType.land,
          price: '20000.00',
          status: ListingStatus.published,
          createdAt: DateTime(2026, 1, 3),
        ),
      ],
    );

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('منشور').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف').last);
    await tester.pumpAndSettle();

    // The confirmation dialog is showing; confirm it.
    await tester.tap(find.text('حذف').last);
    await tester.pumpAndSettle();

    expect(repo.deletes, [3]);
    expect(find.text('أرض للبيع'), findsNothing);
  });

  testWidgets('pausing a published listing calls setStatus with paused', (tester) async {
    container = buildContainer(
      published: [
        Listing(
          id: 4,
          title: 'محل تجاري',
          purpose: ListingPurpose.rent,
          propertyType: PropertyType.shop,
          price: '300.00',
          status: ListingStatus.published,
          createdAt: DateTime(2026, 1, 4),
        ),
      ],
    );

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('منشور').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تعليق'));
    await tester.pumpAndSettle();

    expect(repo.statusChanges, [(4, 'paused')]);
  });

  testWidgets('an empty tab shows the empty state', (tester) async {
    container = buildContainer();
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('منشور').last);
    await tester.pumpAndSettle();

    expect(find.text('لا توجد عقارات بعد'), findsOneWidget);
  });
}
