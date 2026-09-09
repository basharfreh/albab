import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';

/// Price and area share one control shape (brief P7 item 2: "المساحة same [pattern as
/// price]") — two numeric fields plus [PriceRangeSlider], kept in sync in both directions.
/// `null` in either field means that bound is unset (no `min_price`/`max_price` param).
class RangeFilterSection extends StatefulWidget {
  const RangeFilterSection({
    super.key,
    required this.title,
    required this.min,
    required this.max,
    required this.divisions,
    required this.initialMin,
    required this.initialMax,
    required this.labelBuilder,
    required this.onMinChanged,
    required this.onMaxChanged,
  });

  final String title;
  final double min;
  final double max;
  final int divisions;
  final num? initialMin;
  final num? initialMax;
  final String Function(double value) labelBuilder;
  final ValueChanged<num?> onMinChanged;
  final ValueChanged<num?> onMaxChanged;

  @override
  State<RangeFilterSection> createState() => _RangeFilterSectionState();
}

class _RangeFilterSectionState extends State<RangeFilterSection> {
  late RangeValues _values;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    final start = (widget.initialMin?.toDouble() ?? widget.min).clamp(widget.min, widget.max);
    final rawEnd = (widget.initialMax?.toDouble() ?? widget.max).clamp(widget.min, widget.max);
    _values = RangeValues(start, rawEnd < start ? start : rawEnd);
    _minController = TextEditingController(text: widget.initialMin?.round().toString() ?? '');
    _maxController = TextEditingController(text: widget.initialMax?.round().toString() ?? '');
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _onSlider(RangeValues values) {
    setState(() => _values = values);
    _minController.text = values.start.round().toString();
    _maxController.text = values.end.round().toString();
    widget.onMinChanged(values.start.round());
    widget.onMaxChanged(values.end.round());
  }

  void _onMinField(String text) {
    final parsed = num.tryParse(text);
    widget.onMinChanged(parsed);
    if (parsed != null) {
      final clamped = parsed.toDouble().clamp(widget.min, _values.end);
      setState(() => _values = RangeValues(clamped, _values.end));
    }
  }

  void _onMaxField(String text) {
    final parsed = num.tryParse(text);
    widget.onMaxChanged(parsed);
    if (parsed != null) {
      final clamped = parsed.toDouble().clamp(_values.start, widget.max);
      setState(() => _values = RangeValues(_values.start, clamped));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: widget.title),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _minController,
                label: l10n.filterPriceFrom,
                keyboardType: TextInputType.number,
                onChanged: _onMinField,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                controller: _maxController,
                label: l10n.filterPriceTo,
                keyboardType: TextInputType.number,
                onChanged: _onMaxField,
              ),
            ),
          ],
        ),
        PriceRangeSlider(
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          values: _values,
          labelBuilder: widget.labelBuilder,
          onChanged: _onSlider,
        ),
      ],
    );
  }
}
