import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';

/// "تمييز هذا العقار" — same "no owner-facing promotion-request endpoint" gap P9's success
/// screen already hit (only `/admin/promotions/`, `IsAdminRole` — docs/API.md, PROGRESS.md
/// P3/P9 entries). A small self-contained sheet, not shared code with P9's own copy of this
/// (same reasoning as `report_sheet.dart`/`guest_gate.dart` each owning their own small
/// sheet) — both say the same thing because both hit the same backend gap, not because one
/// calls the other.
void showPromotionComingSoonSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.wizardPromotionComingSoonTitle, style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.wizardPromotionComingSoonMessage, style: AppTypography.body),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: l10n.commonDone, onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    ),
  );
}
