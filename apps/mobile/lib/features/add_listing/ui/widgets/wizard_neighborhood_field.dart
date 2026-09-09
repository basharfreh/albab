import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The wizard's own الحي dropdown — a *required* single choice once a location is
/// confirmed, unlike `discovery/ui/widgets/neighborhood_dropdown.dart`'s filter-screen
/// version, which offers "الكل" as a valid "no filter" state. Different semantics, so a
/// small dedicated widget rather than reusing that one with an unused branch.
class WizardNeighborhoodField extends StatelessWidget {
  const WizardNeighborhoodField({
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
    return AppDropdown<int>(
      label: l10n.filterNeighborhood,
      value: neighborhoods.any((n) => n.id == value) ? value : null,
      items: [for (final n in neighborhoods) n.id],
      labelBuilder: (id) => neighborhoods.firstWhere((n) => n.id == id).nameAr,
      enabled: async.hasValue,
      onChanged: onChanged,
    );
  }
}
