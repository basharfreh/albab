import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/connectivity_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Brief P12 item 5: "a connectivity banner". Renders nothing while online (or while the
/// platform hasn't reported a definitive state yet — no banner flash on cold start) and a
/// slim bar at the top of the screen while offline. Meant to sit once at the app's root
/// (`MaterialApp.router`'s `builder`), not per-screen — every route gets it for free.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).value ?? true;
    if (isOnline) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.danger,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 16, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.connectivityOffline,
                style: AppTypography.caption.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
