import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Brief P9 item 5/7 — shown after a successful `POST /listings/{id}/submit/`: the
/// moderation notice, a way to view the (now-pending) listing or start another one, and a
/// promotion-request entry point (UC-38). There is no owner-facing "request a promotion"
/// endpoint anywhere in the API today (only `/admin/promotions/`, `IsAdminRole` — see
/// `docs/PROGRESS.md`'s P3 entry), so the entry point opens an informational sheet rather
/// than a real request flow, instead of inventing an endpoint this mobile-only phase has no
/// business adding.
class AddListingSuccessScreen extends StatelessWidget {
  const AddListingSuccessScreen({
    super.key,
    required this.listingId,
    required this.onAddAnother,
  });

  final int listingId;
  final VoidCallback onAddAnother;

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
                Icons.check_circle_outline,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.wizardSuccessTitle,
                style: AppTypography.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.wizardModerationNotice,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: l10n.wizardSuccessViewListing,
                onPressed: () => context.go('/listing/$listingId'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: l10n.wizardSuccessAddAnother,
                onPressed: onAddAnother,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => _showPromotionComingSoon(context, l10n),
                child: Text(l10n.wizardPromotionEntry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPromotionComingSoon(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.wizardPromotionComingSoonTitle,
                style: AppTypography.title,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.wizardPromotionComingSoonMessage,
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: l10n.commonDone,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
