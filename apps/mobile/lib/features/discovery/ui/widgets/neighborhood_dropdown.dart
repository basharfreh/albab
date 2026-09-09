import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// الحي dropdown, sourced from `GET /neighborhoods/` (brief P7 item 2). Disabled while
/// loading/errored rather than blocking the rest of the filter screen on it.
class NeighborhoodDropdown extends StatelessWidget {
  const NeighborhoodDropdown({
    super.key,
    required this.async,
    required this.value,
    required this.onChanged,
  });

  final AsyncValue<List<Neighborhood>> async;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final neighborhoods = async.value ?? const <Neighborhood>[];
    return AppDropdown<int?>(
      label: l10n.filterNeighborhood,
      value: neighborhoods.any((n) => n.id == value) ? value : null,
      items: [null, ...neighborhoods.map((n) => n.id)],
      labelBuilder: (id) {
        if (id == null) return l10n.filterAll;
        return neighborhoods.firstWhere((n) => n.id == id).nameAr;
      },
      enabled: async.hasValue,
      onChanged: onChanged,
    );
  }
}
