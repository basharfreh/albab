import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';

/// Placeholder for the P11 sections not yet built this slice (المستخدمين، الإعلانات،
/// المعاملات، الإشعارات، التقارير، الإعدادات — see docs/PROGRESS.md). Keeps every sidebar
/// item navigable instead of 404ing, per brief §10 ("every screen handles four states" —
/// this route's one state is simply "not built yet").
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.title),
        const SizedBox(height: AppSpacing.xxxl),
        EmptyState(
          icon: Icons.construction_outlined,
          title: l10n.dashComingSoonTitle,
          message: l10n.dashComingSoonMessage,
        ),
      ],
    );
  }
}
