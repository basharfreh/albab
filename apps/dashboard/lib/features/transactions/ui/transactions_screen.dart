import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/data/admin_models.dart';
import '../../admin/data/admin_repository.dart';

/// المعاملات (UC-57, brief P11 item 6): recorded payments, filterable by status and date,
/// plus a "record payment" dialog that bills a pending [AdminPromotion] and — since a
/// `completed` transaction is what activates a promotion (`services.activate_promotion`,
/// backend) — is how an admin actually turns a pending الإعلانات entry into a live one.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String? _statusFilter;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _loading = true;
  Object? _error;
  List<AdminTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final transactions = await ref
          .read(adminRepositoryProvider)
          .fetchTransactions(
            status: _statusFilter,
            createdAfter: _fromDate,
            // Include the whole "to" day, not just its midnight instant.
            createdBefore: _toDate?.add(const Duration(days: 1)),
          );
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _fromDate : _toDate) ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
    });
    _load();
  }

  Future<void> _openRecordPaymentDialog() async {
    final recorded = await showDialog<AdminTransaction>(
      context: context,
      builder: (context) => const _RecordPaymentDialog(),
    );
    if (recorded == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.dashTransactionRecorded)));
    await _load();
  }

  String _statusLabel(AppLocalizations l10n, String status) =>
      status == 'pending' ? l10n.dashStatusPending : l10n.dashTransactionStatusCompleted;

  String _methodLabel(AppLocalizations l10n, String method) =>
      method == 'cash' ? l10n.dashTransactionMethodCash : l10n.dashTransactionMethodManual;

  // A plain `y-MM-dd` formatter — `apps/dashboard` doesn't depend on `intl` directly (only
  // `albab_core` does), and this filter chip doesn't need locale-aware formatting.
  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.dashNavTransactions, style: AppTypography.title),
            SizedBox(
              width: 200,
              child: AppDropdown<String?>(
                label: l10n.dashStatusFilterLabel,
                value: _statusFilter,
                items: const [null, 'pending', 'completed'],
                labelBuilder: (value) =>
                    value == null ? l10n.dashStatusFilterAll : _statusLabel(l10n, value),
                onChanged: (value) {
                  setState(() => _statusFilter = value);
                  _load();
                },
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickDate(isFrom: true),
              icon: const Icon(Icons.calendar_today_outlined, size: AppIconSizes.inline),
              label: Text(_fromDate == null ? l10n.dashFilterDateFrom : _formatDate(_fromDate!)),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickDate(isFrom: false),
              icon: const Icon(Icons.calendar_today_outlined, size: AppIconSizes.inline),
              label: Text(_toDate == null ? l10n.dashFilterDateTo : _formatDate(_toDate!)),
            ),
            FilledButton.icon(
              onPressed: _openRecordPaymentDialog,
              icon: const Icon(Icons.add, size: AppIconSizes.inline),
              label: Text(l10n.dashRecordPayment),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Builder(
          builder: (context) {
            if (_loading) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final error = _error;
            if (error != null) {
              final message = error is ApiException
                  ? error.localizedMessage(l10n)
                  : l10n.errorUnknown;
              return ErrorState(message: message, onRetry: _load);
            }
            if (_transactions.isEmpty) {
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: l10n.dashEmptyTransactionsTitle,
                message: l10n.dashEmptyTransactionsMessage,
              );
            }
            return Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l10n.dashColOwner)),
                    DataColumn(label: Text(l10n.dashColListing)),
                    DataColumn(label: Text(l10n.dashColAmount)),
                    DataColumn(label: Text(l10n.dashColMethod)),
                    DataColumn(label: Text(l10n.dashColReference)),
                    DataColumn(label: Text(l10n.dashColStatus)),
                    DataColumn(label: Text(l10n.dashColDate)),
                  ],
                  rows: [
                    for (final transaction in _transactions)
                      DataRow(
                        cells: [
                          DataCell(Text(transaction.userName)),
                          DataCell(
                            SizedBox(
                              width: 180,
                              child: Text(
                                transaction.listingTitle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text('${transaction.currency} ${transaction.amount}'),
                            ),
                          ),
                          DataCell(Text(_methodLabel(l10n, transaction.method))),
                          DataCell(Text(transaction.reference)),
                          DataCell(
                            Chip(
                              label: Text(_statusLabel(l10n, transaction.status)),
                              labelStyle: AppTypography.caption.copyWith(
                                color: transaction.status == 'completed'
                                    ? AppColors.primary
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                          DataCell(Text(RelativeTime.format(l10n, transaction.createdAt))),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RecordPaymentDialog extends ConsumerStatefulWidget {
  const _RecordPaymentDialog();

  @override
  ConsumerState<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<_RecordPaymentDialog> {
  final _amountController = TextEditingController();
  final _currencyController = TextEditingController(text: 'USD');
  final _referenceController = TextEditingController();
  bool _loadingPromotions = true;
  List<AdminPromotion> _pendingPromotions = [];
  AdminPromotion? _selectedPromotion;
  String _method = 'cash';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPromotions);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _currencyController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    final promotions = await ref
        .read(adminRepositoryProvider)
        .fetchPromotions(status: 'pending');
    if (!mounted) return;
    setState(() {
      _pendingPromotions = promotions;
      _loadingPromotions = false;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final promotion = _selectedPromotion;
    final amount = _amountController.text.trim();
    if (promotion == null || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorUnknown)));
      return;
    }

    setState(() => _saving = true);
    try {
      final recorded = await ref
          .read(adminRepositoryProvider)
          .createTransaction(
            userId: promotion.listingOwnerId,
            promotionId: promotion.id,
            amount: amount,
            method: _method,
            currency: _currencyController.text.trim().isEmpty
                ? 'USD'
                : _currencyController.text.trim(),
            reference: _referenceController.text.trim().isEmpty
                ? null
                : _referenceController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(recorded);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.dashRecordPayment, style: AppTypography.section),
                const SizedBox(height: AppSpacing.lg),
                if (_loadingPromotions)
                  const Center(child: CircularProgressIndicator())
                else if (_pendingPromotions.isEmpty)
                  Text(
                    l10n.dashNoPendingPromotions,
                    style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                  )
                else ...[
                  AppDropdown<AdminPromotion>(
                    label: l10n.dashTransactionPromotionLabel,
                    value: _selectedPromotion,
                    items: _pendingPromotions,
                    labelBuilder: (p) => '${p.listingTitle} — ${p.listingOwnerName}',
                    onChanged: (value) => setState(() {
                      _selectedPromotion = value;
                      _amountController.text = value?.package.price ?? '';
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: l10n.dashTransactionAmountLabel,
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<String>(
                    label: l10n.dashTransactionMethodLabel,
                    value: _method,
                    items: const ['cash', 'manual'],
                    labelBuilder: (m) =>
                        m == 'cash' ? l10n.dashTransactionMethodCash : l10n.dashTransactionMethodManual,
                    onChanged: (value) => setState(() => _method = value ?? 'cash'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: l10n.dashTransactionCurrencyLabel,
                    controller: _currencyController,
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: l10n.dashTransactionReferenceLabel,
                    controller: _referenceController,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.commonCancel),
                    ),
                    if (_pendingPromotions.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.commonSave),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
