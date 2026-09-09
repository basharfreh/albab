import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/wizard_draft.dart';

/// Groups digits into `12,345` while typing — brief P9 item 2: "price with a `$` prefix and
/// thousands separators while typing." Hand-rolled rather than `NumberFormat` fed through an
/// `InputFormatter` on every keystroke, to keep full control over cursor position; the digits
/// underneath (what's actually sent to the API/stored in [WizardDraft.price]) are untouched.
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Brief P9 item 2 — step 1 of the wizard: title, type, purpose, price, bedrooms/bathrooms
/// counters, description. Every field writes straight into [wizardDraftProvider] on change,
/// so the provider is always the single source of truth (no separate local form state to
/// keep in sync) — only the price field needs its own [TextEditingController], for the
/// thousands-separator display.
class Step1Info extends ConsumerStatefulWidget {
  const Step1Info({super.key});

  @override
  ConsumerState<Step1Info> createState() => _Step1InfoState();
}

class _Step1InfoState extends ConsumerState<Step1Info> {
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(wizardDraftProvider);
    _titleController = TextEditingController(text: draft.title);
    _priceController = TextEditingController(
      text: draft.price == null
          ? ''
          : _ThousandsSeparatorFormatter()
                .formatEditUpdate(
                  TextEditingValue.empty,
                  TextEditingValue(text: draft.price!),
                )
                .text,
    );
    _descriptionController = TextEditingController(text: draft.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = ref.watch(wizardDraftProvider);
    final notifier = ref.read(wizardDraftProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        AppTextField(
          controller: _titleController,
          label: l10n.wizardTitleLabel,
          hint: l10n.wizardTitleHint,
          onChanged: notifier.setTitle,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppDropdown<PropertyType>(
          label: l10n.filterPropertyType,
          value: draft.propertyType,
          items: PropertyType.values,
          labelBuilder: (t) => t.label(l10n),
          onChanged: (value) {
            if (value != null) notifier.setPropertyType(value);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _PurposeSegmented(value: draft.purpose, onChanged: notifier.setPurpose),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [_ThousandsSeparatorFormatter()],
          decoration: InputDecoration(
            labelText: l10n.wizardPriceLabel,
            prefixText: r'$ ',
          ),
          onChanged: (value) => notifier.setPrice(value.replaceAll(',', '')),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Row(
            children: [
              Checkbox(
                value: draft.isNegotiable,
                onChanged: (value) => notifier.setNegotiable(value ?? false),
              ),
              Text(l10n.wizardNegotiable, style: AppTypography.body),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CounterField(
          label: l10n.wizardBedroomsCount,
          value: draft.bedrooms,
          onChanged: notifier.setBedrooms,
        ),
        const SizedBox(height: AppSpacing.md),
        CounterField(
          label: l10n.wizardBathroomsCount,
          value: draft.bathrooms,
          onChanged: notifier.setBathrooms,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          controller: _descriptionController,
          label: l10n.wizardDescriptionLabel,
          maxLines: 5,
          maxLength: 1000,
          onChanged: notifier.setDescription,
        ),
      ],
    );
  }
}

class _PurposeSegmented extends StatelessWidget {
  const _PurposeSegmented({required this.value, required this.onChanged});

  final ListingPurpose value;
  final ValueChanged<ListingPurpose> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<ListingPurpose>(
      segments: [
        for (final purpose in ListingPurpose.values)
          ButtonSegment(
            value: purpose,
            icon: Icon(purpose.icon, size: AppIconSizes.inline),
            label: Text(purpose.label(l10n)),
          ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
