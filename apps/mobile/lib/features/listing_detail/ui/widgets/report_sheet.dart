import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';

/// UC-20's fixed reason list — the API (`ReportCreateSerializer.reason`, `CharField`) takes
/// any string, so these wire values are this screen's own vocabulary, not a backend enum.
enum ReportReason { inappropriate, misleading, duplicate, fraud, other }

extension on ReportReason {
  String get wireValue => name;

  String label(AppLocalizations l10n) => switch (this) {
    ReportReason.inappropriate => l10n.reportReasonInappropriate,
    ReportReason.misleading => l10n.reportReasonMisleading,
    ReportReason.duplicate => l10n.reportReasonDuplicate,
    ReportReason.fraud => l10n.reportReasonFraud,
    ReportReason.other => l10n.reportReasonOther,
  };
}

/// Brief P8 item 6: overflow menu → reason sheet → `POST /listings/{id}/report/` →
/// confirmation snackbar. Returns the chosen `(reason, note)` pair on submit, or `null` if
/// dismissed — the caller (the detail screen) owns the actual API call and snackbar so it
/// can also handle the unauthenticated case with the shared guest-gate sheet.
Future<(String reason, String? note)?> showReportSheet(BuildContext context) {
  return showModalBottomSheet<(String, String?)>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (context) => const _ReportSheetContent(),
  );
}

class _ReportSheetContent extends StatefulWidget {
  const _ReportSheetContent();

  @override
  State<_ReportSheetContent> createState() => _ReportSheetContentState();
}

class _ReportSheetContentState extends State<_ReportSheetContent> {
  ReportReason _selected = ReportReason.inappropriate;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.reportSheetTitle, style: AppTypography.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.reportReasonLabel, style: AppTypography.label),
          const SizedBox(height: AppSpacing.xs),
          RadioGroup<ReportReason>(
            groupValue: _selected,
            onChanged: (value) => setState(() => _selected = value!),
            child: Column(
              children: [
                for (final reason in ReportReason.values)
                  RadioListTile<ReportReason>(
                    contentPadding: EdgeInsets.zero,
                    value: reason,
                    title: Text(reason.label(l10n)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _noteController,
            label: l10n.reportNoteLabel,
            maxLines: 3,
            maxLength: 500,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: l10n.reportSubmit,
            onPressed: () => Navigator.of(
              context,
            ).pop((_selected.wireValue, _noteController.text.trim())),
          ),
        ],
      ),
    );
  }
}
