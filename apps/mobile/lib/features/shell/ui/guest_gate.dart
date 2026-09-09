import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The bottom sheet P5's redirect rules describe: tapping Messages/Favorites/Add/Account
/// while unauthenticated offers login/register instead of switching tabs. Because the shell
/// never calls `goBranch` before showing this, dismissing it (any way — swipe, scrim tap, a
/// button) leaves the previously-selected tab exactly as it was.
Future<void> showGuestGateSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 40, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.authGuestGateTitle,
                style: AppTypography.section,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.authGuestGateMessage,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: l10n.authLogin,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/login');
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: l10n.authRegister,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/register');
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
