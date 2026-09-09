import 'package:flutter/material.dart';

import '../theme/app_icon_sizes.dart';
import '../theme/app_spacing.dart';

/// Outlined counterpart to [PrimaryButton] — same metrics, a `border`-token stroke, styled
/// entirely through [AppTheme]'s `outlinedButtonTheme`.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSizes.inline),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(label),
        ],
      ),
    );
  }
}
