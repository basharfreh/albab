import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A labeled [RangeSlider] — the filter screen (brief P7) uses this for both price and area
/// ranges, each paired with two numeric text fields that stay in sync with it. [labelBuilder]
/// formats each end value for display (`Money.format` for price, `Area.format` for area) so
/// this widget makes no currency/unit assumption of its own.
class PriceRangeSlider extends StatelessWidget {
  const PriceRangeSlider({
    super.key,
    required this.min,
    required this.max,
    required this.values,
    required this.onChanged,
    required this.labelBuilder,
    this.divisions,
  });

  final double min;
  final double max;
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;
  final String Function(double value) labelBuilder;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RangeSlider(
          min: min,
          max: max,
          divisions: divisions,
          values: values,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.border,
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(labelBuilder(values.start), style: AppTypography.label),
            Text(labelBuilder(values.end), style: AppTypography.label),
          ],
        ),
      ],
    );
  }
}
