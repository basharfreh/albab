import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';

/// عدد الغرف as chips: الكل · 1 · 2 · 3 · 4 · +5 (brief P7 item 2).
class BedroomsSelector extends StatelessWidget {
  const BedroomsSelector({super.key, required this.value, required this.onChanged});

  /// `null` (الكل), `"1"`..`"4"` (exact) or `"5+"` (at least) — the exact wire values
  /// brief §8 defines for `bedrooms`.
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = <String?, String>{
      null: l10n.filterBedroomsAll,
      '1': '1',
      '2': '2',
      '3': '3',
      '4': '4',
      '5+': l10n.filterBedrooms5Plus,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.filterBedroomsLabel),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final entry in options.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: value == entry.key,
                // A radio group, not a toggle (unlike purpose) — "الكل" is its own
                // explicit chip per brief P7 item 2, so every tap picks exactly one option.
                onSelected: (_) => onChanged(entry.key),
              ),
          ],
        ),
      ],
    );
  }
}
