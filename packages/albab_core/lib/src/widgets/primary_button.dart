import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icon_sizes.dart';
import '../theme/app_spacing.dart';

/// Filled, full-width green button (brief §9). Metrics (height 48, radius 12, weight 600)
/// come from [AppTheme]'s `elevatedButtonTheme` — this widget only adds the loading/icon
/// affordances so screens never restate the styling themselves.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.surface),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppIconSizes.inline),
                  const SizedBox(width: AppSpacing.sm),
                ],
                // `Flexible` + ellipsis rather than a bare `Text`: this button is also used
                // at a fixed, narrow width (e.g. `EmptyState`/`ErrorState`'s 200px retry
                // button) — a long label there should shrink gracefully instead of
                // overflowing the Row.
                Flexible(
                  child: Text(label, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
    );
  }
}
