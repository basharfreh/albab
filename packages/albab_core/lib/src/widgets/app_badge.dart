import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A small pill badge (status chips like "منشور"/"مرفوض") or a count/dot badge (the red
/// unread indicators on Messages/Notifications, brief §9's `danger` color).
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, required this.color, this.background})
    : _isDot = false,
      count = null;

  /// A small red dot with a number, for unread counts on nav/list rows. `count == 0` hides
  /// the badge entirely (an `AppBadge.count(0, ...)` at a call site is a no-op by design).
  const AppBadge.count(this.count, {super.key})
    : _isDot = true,
      label = '',
      color = AppColors.surface,
      background = AppColors.danger;

  final String label;
  final Color color;
  final Color? background;
  final int? count;
  final bool _isDot;

  @override
  Widget build(BuildContext context) {
    if (_isDot) {
      final value = count ?? 0;
      if (value <= 0) return const SizedBox.shrink();
      // No `alignment` here on purpose: Container+alignment expands to fill any bounded
      // parent (this badge sits inside a `Wrap`, inside a `stretch`-aligned Column in the
      // gallery — that combination turned "alignment: Alignment.center" into a full-width
      // red bar). Symmetric padding centers the digit just as well without that risk.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        constraints: const BoxConstraints(minWidth: 18),
        decoration: BoxDecoration(color: background, borderRadius: AppRadius.pillRadius),
        child: Text(
          value > 99 ? '99+' : '$value',
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(color: AppColors.surface, height: 1),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: background ?? AppColors.primaryTint,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(label, style: AppTypography.caption.copyWith(color: color, height: 1)),
    );
  }
}
