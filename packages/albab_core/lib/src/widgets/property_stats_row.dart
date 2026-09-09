import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../format/area.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The three-column area/bedrooms/bathrooms row from the listing detail screen (brief §5),
/// separated by hairline dividers. Any stat left `null` is simply omitted, not shown as 0 —
/// land listings, say, have no bedroom count at all.
class PropertyStatsRow extends StatelessWidget {
  const PropertyStatsRow({super.key, this.areaSqm, this.bedrooms, this.bathrooms});

  final String? areaSqm;
  final int? bedrooms;
  final int? bathrooms;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = <(IconData, String, String)>[
      if (areaSqm != null)
        (Icons.straighten_outlined, l10n.statsAreaLabel, Area.format(l10n, num.parse(areaSqm!))),
      if (bedrooms != null)
        (Icons.bed_outlined, l10n.statsBedroomsLabel, '$bedrooms'),
      if (bathrooms != null)
        (Icons.bathtub_outlined, l10n.statsBathroomsLabel, '$bathrooms'),
    ];

    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const _StatDivider(),
          Expanded(child: _StatColumn(stats[i])),
        ],
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn(this.stat);

  final (IconData, String, String) stat;

  @override
  Widget build(BuildContext context) {
    final (icon, label, value) = stat;
    return Column(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTypography.section),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 48,
      child: VerticalDivider(color: AppColors.border, width: AppSpacing.lg, thickness: 1),
    );
  }
}
