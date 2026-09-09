import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

/// Mirrors `apps.catalog.models.PropertyType`. Pin colors are the brief §9 map-legend /
/// by-type-pie palette — the map and the admin pie chart must never diverge from this.
enum PropertyType {
  house(icon: Icons.home_outlined, pinColor: AppPropertyTypeColors.house),
  apartment(icon: Icons.apartment_outlined, pinColor: AppPropertyTypeColors.apartment),
  shop(icon: Icons.storefront_outlined, pinColor: AppPropertyTypeColors.shop),
  land(icon: Icons.landscape_outlined, pinColor: AppPropertyTypeColors.land),
  other(icon: Icons.category_outlined, pinColor: AppPropertyTypeColors.other);

  const PropertyType({required this.icon, required this.pinColor});

  final IconData icon;
  final Color pinColor;

  String get wireValue => name;

  String label(AppLocalizations l10n) => switch (this) {
    PropertyType.house => l10n.propertyTypeHouse,
    PropertyType.apartment => l10n.propertyTypeApartment,
    PropertyType.shop => l10n.propertyTypeShop,
    PropertyType.land => l10n.propertyTypeLand,
    PropertyType.other => l10n.propertyTypeOther,
  };
}
