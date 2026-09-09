import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';

/// Brief P9 item 7 — "quota rejection from the API renders as a friendly Arabic screen
/// offering the agency upgrade." [message] is the server's own Arabic text
/// (`apps/catalog/services/quota.py`'s `check_quota`, surfaced through submit's `ApiException
/// .message`) — no separate copy of that wording is kept here, so it can never drift out of
/// sync with whatever the quota numbers actually are server-side.
///
/// There is no in-app role-upgrade flow (changing `role` to `agency` is an admin-only action,
/// `POST /admin/users/{id}/role/`) — the "offering the upgrade" is informational text with a
/// support contact pointer, not a working self-service upgrade button, since inventing one
/// would mean adding an endpoint this mobile-only phase has no business adding.
class QuotaScreen extends StatelessWidget {
  const QuotaScreen({super.key, required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_disabled_outlined,
                size: 64,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.wizardQuotaTitle,
                style: AppTypography.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Text(
                        l10n.wizardQuotaUpgradeCta,
                        style: AppTypography.section,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.wizardQuotaUpgradeInfo,
                        style: AppTypography.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: l10n.commonDone, onPressed: onClose),
            ],
          ),
        ),
      ),
    );
  }
}
