import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';

/// The للبيع/للإيجار segment of the filter screen (brief P7 item 2).
class PurposeSelector extends StatelessWidget {
  const PurposeSelector({super.key, required this.value, required this.onChanged});

  final ListingPurpose? value;
  final ValueChanged<ListingPurpose?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final purpose in ListingPurpose.values)
          ChoiceChip(
            label: Text(purpose.label(l10n)),
            avatar: Icon(purpose.icon, size: AppIconSizes.inline),
            // Tapping the already-selected chip clears it back to "both" — neither
            // purpose selected means no `purpose` filter is applied (brief §8 has no
            // explicit "both" wire value; omitting the param is that state).
            selected: value == purpose,
            onSelected: (selected) => onChanged(selected ? purpose : null),
          ),
      ],
    );
  }
}
