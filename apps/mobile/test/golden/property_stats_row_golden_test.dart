import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

void main() {
  testWidgets('all three stats — Arabic', (tester) async {
    pinSurfaceSize(tester, const Size(360, 120));
    await tester.pumpWidget(
      wrapForGolden(
        const Center(
          child: SizedBox(
            width: 320,
            child: PropertyStatsRow(areaSqm: '180', bedrooms: 3, bathrooms: 2),
          ),
        ),
      ),
    );
    await settleImages(tester);

    await expectLater(
      find.byType(PropertyStatsRow),
      matchesGoldenFile('goldens/property_stats_row_full_ar.png'),
    );
  });

  testWidgets('all three stats — English', (tester) async {
    pinSurfaceSize(tester, const Size(360, 120));
    await tester.pumpWidget(
      wrapForGolden(
        const Center(
          child: SizedBox(
            width: 320,
            child: PropertyStatsRow(areaSqm: '180', bedrooms: 3, bathrooms: 2),
          ),
        ),
        locale: const Locale('en'),
      ),
    );
    await settleImages(tester);

    await expectLater(
      find.byType(PropertyStatsRow),
      matchesGoldenFile('goldens/property_stats_row_full_en.png'),
    );
  });

  testWidgets('area only — a land listing with no bedroom/bathroom count', (tester) async {
    pinSurfaceSize(tester, const Size(360, 120));
    await tester.pumpWidget(
      wrapForGolden(
        const Center(
          child: SizedBox(width: 320, child: PropertyStatsRow(areaSqm: '500')),
        ),
      ),
    );
    await settleImages(tester);

    await expectLater(
      find.byType(PropertyStatsRow),
      matchesGoldenFile('goldens/property_stats_row_area_only_ar.png'),
    );
  });
}
