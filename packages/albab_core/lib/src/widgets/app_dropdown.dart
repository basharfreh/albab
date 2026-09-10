import 'package:flutter/material.dart';

/// Generic dropdown — styled through [AppTheme]'s `inputDecorationTheme` like every other
/// field. [labelBuilder] turns each [T] into its display string, so callers can hand it
/// enums (`PropertyType.values`), [Neighborhood] lists, or anything else.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      // Without `isExpanded`, the button sizes itself to the widest item's intrinsic width
      // instead of the space actually available — on a narrow parent (a phone-width browser
      // window, or any card packed tightly next to a collapsed sidebar) that overflows
      // instead of truncating. Found live at ~190px available width, not a contrived case.
      isExpanded: true,
      items: [
        for (final item in items)
          DropdownMenuItem(
            value: item,
            child: Text(labelBuilder(item), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}
