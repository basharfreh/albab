import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

/// Mirrors `apps.catalog.models.ListingStatus`.
enum ListingStatus {
  draft(icon: Icons.edit_note_outlined, color: AppColors.textMuted),
  pending(icon: Icons.hourglass_empty, color: AppColors.warning),
  published(icon: Icons.check_circle_outline, color: AppColors.primary),
  rejected(icon: Icons.cancel_outlined, color: AppColors.danger),
  sold(icon: Icons.paid_outlined, color: AppColors.textSecondary),
  rented(icon: Icons.vpn_key_outlined, color: AppColors.textSecondary),
  paused(icon: Icons.pause_circle_outline, color: AppColors.textMuted);

  const ListingStatus({required this.icon, required this.color});

  final IconData icon;

  /// Status-chip color (mockup's status badges on `عقاراتي`, brief P10).
  final Color color;

  String get wireValue => name;

  String label(AppLocalizations l10n) => switch (this) {
    ListingStatus.draft => l10n.listingStatusDraft,
    ListingStatus.pending => l10n.listingStatusPending,
    ListingStatus.published => l10n.listingStatusPublished,
    ListingStatus.rejected => l10n.listingStatusRejected,
    ListingStatus.sold => l10n.listingStatusSold,
    ListingStatus.rented => l10n.listingStatusRented,
    ListingStatus.paused => l10n.listingStatusPaused,
  };
}
