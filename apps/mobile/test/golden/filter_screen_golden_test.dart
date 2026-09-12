import 'package:albab_core/albab_core.dart';
import 'package:albab_mobile/features/discovery/data/map_filters.dart';
import 'package:albab_mobile/features/discovery/ui/filter_screen.dart';
import 'package:albab_mobile/features/map/data/listings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

/// Same fake used by `filter_screen_test.dart` — a fixed count and one neighborhood is enough
/// to render every section of the sheet without a real backend.
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

Widget _wrap({required Locale locale}) {
  final container = ProviderContainer(
    overrides: [
      listingsRepositoryProvider.overrideWith((ref) => _FakeListingsRepository(ref)),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      home: const FilterScreen(),
    ),
  );
}

void main() {
  testWidgets('filter sheet in its default state — Arabic', (tester) async {
    pinSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(_wrap(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(FilterScreen),
      matchesGoldenFile('goldens/filter_screen_ar.png'),
    );
  });

  testWidgets('filter sheet in its default state — English', (tester) async {
    pinSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(_wrap(locale: const Locale('en')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(FilterScreen),
      matchesGoldenFile('goldens/filter_screen_en.png'),
    );
  });
}
