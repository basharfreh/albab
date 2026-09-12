import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The bottom-of-list row a `ListView` shows while it has more pages to load (brief P12
/// item 5: "no infinite spinners"). A plain spinner with no [hasError] branch — which every
/// paginated list in this app used to hard-code inline — never resolves once a "load more"
/// request actually fails: `hasMore` stays true, `loading` goes back to false, and the
/// spinner just sits there forever with no way to retry. This renders a tappable retry row
/// instead whenever the last attempt failed.
class PaginationFooter extends StatelessWidget {
  const PaginationFooter({super.key, required this.hasError, this.onRetry});

  final bool hasError;
  final VoidCallback? onRetry;

  /// Both branches below render at exactly this height — if the spinner and the retry row
  /// had different heights, switching between them on failure would shift `maxScrollExtent`
  /// while sitting right at the bottom of the list, re-crossing the "near bottom" threshold
  /// and silently firing another `onRetry`-equivalent request on every state change. A fixed
  /// height keeps a failure a single, deliberate event instead of a retry cascade.
  static const _height = 56.0;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      final l10n = AppLocalizations.of(context)!;
      return SizedBox(
        height: _height,
        child: Center(
          child: InkWell(
            onTap: onRetry,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, size: 16, color: AppColors.danger),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.paginationLoadMoreFailed,
                    style: AppTypography.body.copyWith(color: AppColors.danger),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox(
      height: _height,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
