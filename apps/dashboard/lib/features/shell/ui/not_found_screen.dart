import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Brief P11 item 9: "a real 404 route" — `GoRouter.errorBuilder` fires for any unmatched
/// location, so this renders standalone (like `/login`/`/`), not inside `DashboardShell`.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.dash404Title, style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.dash404Message,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: Text(l10n.dash404GoHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
