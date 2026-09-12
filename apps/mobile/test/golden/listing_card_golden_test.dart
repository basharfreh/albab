import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_utils.dart';

const _forSale = Listing(
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

const _forRent = Listing(
  id: 2,
  title: 'أرض للإيجار',
  neighborhoodName: 'حي الشهداء',
  price: '400.00',
  imagesCount: 0,
  purpose: ListingPurpose.rent,
  propertyType: PropertyType.land,
);

void main() {
  setUp(() {
    // Deterministic geometry: golden PNGs must not depend on the host's default surface.
  });

  testWidgets('vertical card — Arabic, negotiable, full stats', (tester) async {
    pinSurfaceSize(tester, const Size(360, 320));
    await tester.pumpWidget(
      wrapForGolden(
        const Center(
          child: SizedBox(width: 320, child: ListingCard(listing: _forSale)),
        ),
      ),
    );
    await settleImages(tester);

    await expectLater(
      find.byType(ListingCard),
      matchesGoldenFile('goldens/listing_card_vertical_ar.png'),
    );
  });

  testWidgets('vertical card — English, no stats, no cover', (tester) async {
    pinSurfaceSize(tester, const Size(360, 320));
    await tester.pumpWidget(
      wrapForGolden(
        const Center(
          child: SizedBox(width: 320, child: ListingCard(listing: _forRent)),
        ),
        locale: const Locale('en'),
      ),
    );
    await settleImages(tester);

    await expectLater(
      find.byType(ListingCard),
      matchesGoldenFile('goldens/listing_card_vertical_en.png'),
    );
  });

  testWidgets('horizontal (map peek) card — Arabic, favorited', (tester) async {
    pinSurfaceSize(tester, const Size(400, 140));
    await tester.pumpWidget(
      wrapForGolden(
        Center(
          child: SizedBox(
            width: 360,
            child: ListingCard(
              listing: _forSale.copyWith(isFavorited: true),
              layout: ListingCardLayout.horizontal,
            ),
          ),
        ),
      ),
    );
    await settleImages(tester);

    await expectLater(
      find.byType(ListingCard),
      matchesGoldenFile('goldens/listing_card_horizontal_ar.png'),
    );
  });
}
