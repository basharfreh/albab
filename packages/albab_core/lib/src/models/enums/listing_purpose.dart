import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Mirrors `apps.catalog.models.ListingPurpose`.
enum ListingPurpose {
  sale(icon: Icons.sell_outlined),
  rent(icon: Icons.key_outlined);

  const ListingPurpose({required this.icon});

  final IconData icon;

  String get wireValue => name;

  String label(AppLocalizations l10n) => switch (this) {
    ListingPurpose.sale => l10n.purposeSale,
    ListingPurpose.rent => l10n.purposeRent,
  };
}
