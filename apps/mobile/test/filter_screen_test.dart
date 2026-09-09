import 'package:albab_core/albab_core.dart';
import 'package:albab_mobile/features/discovery/data/map_filters.dart';
import 'package:albab_mobile/features/discovery/ui/filter_screen.dart';
import 'package:albab_mobile/features/map/data/listings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Records the filters each live-count request carried and returns a settable [count] —
/// lets tests drive the "Done when" behavior (brief P7: "every control changes the count
/// within one debounce; ... clearing restores the unfiltered count") without a real backend.
class _FakeListingsRepository extends ListingsRepository {
  _FakeListingsRepository(super.ref);

  int count = 0;
  MapFilters? lastCountFilters;
  List<Neighborhood> neighborhoods = const [];

  @override
  Future<int> fetchResultsCount(MapFilters filters) async {
    lastCountFilters = filters;
    return count;
  }

  @override
  Future<List<Neighborhood>> fetchNeighborhoods() async => neighborhoods;
}

Widget _appWithFilterRoute(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/filters'),
              child: const Text('open filters'),
            ),
          ),
        ),
      ),
      GoRoute(path: '/filters', builder: (context, state) => const FilterScreen()),
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
  late _FakeListingsRepository fakeRepo;
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        listingsRepositoryProvider.overrideWith((ref) => _FakeListingsRepository(ref)),
      ],
    );
    addTearDown(container.dispose);
    // Forces the provider to build now, not lazily on `FilterScreen`'s first `initState`
    // (which only runs once the test navigates there) — tests set `fakeRepo.count` before
    // that navigation happens.
    fakeRepo = container.read(listingsRepositoryProvider) as _FakeListingsRepository;
  });

  testWidgets('a control change refetches the live count after its debounce, not before', (
    tester,
  ) async {
    fakeRepo.count = 5;
    await tester.pumpWidget(_appWithFilterRoute(container));
    await tester.tap(find.text('open filters'));
    await tester.pumpAndSettle();

    expect(find.text('عرض النتائج (5)'), findsOneWidget);

    fakeRepo.count = 9;
    await tester.ensureVisible(find.text('3')); // bedrooms chip, below the fold
    await tester.tap(find.text('3'));
    await tester.pump();
    // Still the old count — the 350ms debounce hasn't elapsed yet.
    expect(find.text('عرض النتائج (5)'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('عرض النتائج (9)'), findsOneWidget);
    expect(fakeRepo.lastCountFilters!.bedrooms, '3');
  });

  testWidgets('reset clears the draft and immediately restores the unfiltered count', (
    tester,
  ) async {
    fakeRepo.count = 5;
    await tester.pumpWidget(_appWithFilterRoute(container));
    await tester.tap(find.text('open filters'));
    await tester.pumpAndSettle();

    fakeRepo.count = 9;
    await tester.ensureVisible(find.text('3'));
    await tester.tap(find.text('3'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('عرض النتائج (9)'), findsOneWidget);

    fakeRepo.count = 5;
    await tester.tap(find.text('إعادة تعيين'));
    await tester.pumpAndSettle();

    expect(find.text('عرض النتائج (5)'), findsOneWidget);
    expect(fakeRepo.lastCountFilters!.bedrooms, isNull);
  });

  testWidgets('applying commits the draft into mapFiltersProvider and returns to the caller', (
    tester,
  ) async {
    await tester.pumpWidget(_appWithFilterRoute(container));
    await tester.tap(find.text('open filters'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('للبيع')); // purpose: sale
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton)); // the apply button
    await tester.pumpAndSettle();

    expect(find.text('open filters'), findsOneWidget);
    expect(container.read(mapFiltersProvider).purpose, ListingPurpose.sale);
  });
}
