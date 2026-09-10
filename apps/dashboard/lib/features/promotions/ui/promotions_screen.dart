import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/data/admin_models.dart';
import '../../admin/data/admin_repository.dart';

enum _PromotionsSection { packages, active }

/// الإعلانات (UC-56, brief P11 item 6): promotion packages CRUD, and the list of promotions
/// applied to listings with days remaining. Closes the `PromotionPackage` gap P3 flagged and
/// every P11 entry since has repeated — there was no way to list packages for a picker
/// before this session added `/admin/promotion-packages/`.
///
/// **Simplification**: creating a promotion asks for a listing id (plain number field), not a
/// listing search/picker — `apps/dashboard` has no reusable listing-search widget yet (the
/// closest thing, `ListingsScreen`'s table, isn't packaged as a picker). Flagged, not hidden.
class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  _PromotionsSection _section = _PromotionsSection.packages;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.dashNavPromotions, style: AppTypography.title),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: Text(l10n.dashPromotionsPackagesTab),
              selected: _section == _PromotionsSection.packages,
              onSelected: (_) => setState(() => _section = _PromotionsSection.packages),
            ),
            ChoiceChip(
              label: Text(l10n.dashPromotionsActiveTab),
              selected: _section == _PromotionsSection.active,
              onSelected: (_) => setState(() => _section = _PromotionsSection.active),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        switch (_section) {
          _PromotionsSection.packages => const _PackagesSection(),
          _PromotionsSection.active => const _ActivePromotionsSection(),
        },
      ],
    );
  }
}

class _PackagesSection extends ConsumerStatefulWidget {
  const _PackagesSection();

  @override
  ConsumerState<_PackagesSection> createState() => _PackagesSectionState();
}

class _PackagesSectionState extends ConsumerState<_PackagesSection> {
  bool _loading = true;
  Object? _error;
  List<AdminPromotionPackage> _packages = [];

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
      final packages = await ref.read(adminRepositoryProvider).fetchPromotionPackages();
      if (!mounted) return;
      setState(() {
        _packages = packages;
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

  Future<void> _openDialog({AdminPromotionPackage? existing}) async {
    final saved = await showDialog<AdminPromotionPackage>(
      context: context,
      builder: (context) => _PackageDialog(existing: existing),
    );
    if (saved == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dashPackageSaved)));
    await _load();
  }

  Future<void> _delete(AdminPromotionPackage package) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dashConfirmDeleteTitle),
        content: Text(l10n.dashConfirmDeletePackageMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminRepositoryProvider).deletePromotionPackage(package.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.dashPackageDeleted)));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: OutlinedButton.icon(
            onPressed: () => _openDialog(),
            icon: const Icon(Icons.add, size: AppIconSizes.inline),
            label: Text(l10n.dashAddPackage),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
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
            if (_packages.isEmpty) {
              return EmptyState(
                icon: Icons.campaign_outlined,
                title: l10n.dashEmptyPackagesTitle,
                message: l10n.dashEmptyPackagesMessage,
              );
            }
            return Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l10n.dashColNameAr)),
                    DataColumn(label: Text(l10n.dashColNameEn)),
                    DataColumn(label: Text(l10n.dashColDays)),
                    DataColumn(label: Text(l10n.dashColPrice)),
                    DataColumn(label: Text(l10n.dashColActive)),
                    DataColumn(label: Text(l10n.dashColActions)),
                  ],
                  rows: [
                    for (final package in _packages)
                      DataRow(
                        cells: [
                          DataCell(Text(package.nameAr)),
                          DataCell(Text(package.nameEn)),
                          DataCell(Text('${package.days}')),
                          DataCell(
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(Money.format(package.price)),
                            ),
                          ),
                          DataCell(
                            Chip(
                              label: Text(package.isActive ? l10n.dashActive : l10n.dashInactive),
                              labelStyle: AppTypography.caption.copyWith(
                                color: package.isActive
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _openDialog(existing: package),
                                  child: Text(l10n.commonEdit),
                                ),
                                TextButton(
                                  onPressed: () => _delete(package),
                                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                                  child: Text(l10n.commonDelete),
                                ),
                              ],
                            ),
                          ),
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

class _PackageDialog extends ConsumerStatefulWidget {
  const _PackageDialog({this.existing});

  final AdminPromotionPackage? existing;

  @override
  ConsumerState<_PackageDialog> createState() => _PackageDialogState();
}

class _PackageDialogState extends ConsumerState<_PackageDialog> {
  late final _nameArController = TextEditingController(text: widget.existing?.nameAr);
  late final _nameEnController = TextEditingController(text: widget.existing?.nameEn);
  late final _daysController = TextEditingController(text: widget.existing?.days.toString());
  late final _priceController = TextEditingController(text: widget.existing?.price);
  late bool _isActive = widget.existing?.isActive ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _daysController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final days = int.tryParse(_daysController.text.trim());
    if (days == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorUnknown)));
      return;
    }

    setState(() => _saving = true);
    final draft = AdminPromotionPackage(
      id: widget.existing?.id ?? 0,
      nameAr: _nameArController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      days: days,
      price: _priceController.text.trim(),
      isActive: _isActive,
    );
    try {
      final repo = ref.read(adminRepositoryProvider);
      final saved = widget.existing == null
          ? await repo.createPromotionPackage(draft)
          : await repo.updatePromotionPackage(draft);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
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
    final isEdit = widget.existing != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEdit ? l10n.dashEditPackage : l10n.dashAddPackage, style: AppTypography.section),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(label: l10n.dashPackageNameArLabel, controller: _nameArController),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: l10n.dashPackageNameEnLabel, controller: _nameEnController),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.dashPackageDaysLabel,
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.dashPackagePriceLabel,
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value ?? true),
                  title: Text(l10n.dashPackageActiveLabel),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.commonCancel),
                    ),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivePromotionsSection extends ConsumerStatefulWidget {
  const _ActivePromotionsSection();

  @override
  ConsumerState<_ActivePromotionsSection> createState() => _ActivePromotionsSectionState();
}

class _ActivePromotionsSectionState extends ConsumerState<_ActivePromotionsSection> {
  bool _loading = true;
  Object? _error;
  List<AdminPromotion> _promotions = [];

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
      final promotions = await ref.read(adminRepositoryProvider).fetchPromotions();
      if (!mounted) return;
      setState(() {
        _promotions = promotions;
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

  Future<void> _openCreateDialog() async {
    final created = await showDialog<AdminPromotion>(
      context: context,
      builder: (context) => const _CreatePromotionDialog(),
    );
    if (created == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.dashPromotionCreated)));
    await _load();
  }

  String _statusLabel(AppLocalizations l10n, String status) => switch (status) {
    'pending' => l10n.dashStatusPending,
    'active' => l10n.dashPromotionStatusActive,
    'expired' => l10n.dashPromotionStatusExpired,
    _ => status,
  };

  Color _statusColor(String status) => switch (status) {
    'active' => AppColors.primary,
    'expired' => AppColors.textSecondary,
    _ => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: OutlinedButton.icon(
            onPressed: _openCreateDialog,
            icon: const Icon(Icons.add, size: AppIconSizes.inline),
            label: Text(l10n.dashAddPromotion),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
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
            if (_promotions.isEmpty) {
              return EmptyState(
                icon: Icons.campaign_outlined,
                title: l10n.dashEmptyPromotionsTitle,
                message: l10n.dashEmptyPromotionsMessage,
              );
            }
            return Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l10n.dashColListing)),
                    DataColumn(label: Text(l10n.dashColOwner)),
                    DataColumn(label: Text(l10n.dashColPackage)),
                    DataColumn(label: Text(l10n.dashColDaysRemaining)),
                    DataColumn(label: Text(l10n.dashColStatus)),
                  ],
                  rows: [
                    for (final promotion in _promotions)
                      DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Text(
                                promotion.listingTitle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(promotion.listingOwnerName)),
                          DataCell(Text(promotion.package.nameAr)),
                          DataCell(
                            Text(
                              promotion.daysRemaining == null
                                  ? ''
                                  : '${promotion.daysRemaining}',
                            ),
                          ),
                          DataCell(
                            Chip(
                              label: Text(_statusLabel(l10n, promotion.status)),
                              labelStyle: AppTypography.caption.copyWith(
                                color: _statusColor(promotion.status),
                              ),
                            ),
                          ),
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

class _CreatePromotionDialog extends ConsumerStatefulWidget {
  const _CreatePromotionDialog();

  @override
  ConsumerState<_CreatePromotionDialog> createState() => _CreatePromotionDialogState();
}

class _CreatePromotionDialogState extends ConsumerState<_CreatePromotionDialog> {
  final _listingIdController = TextEditingController();
  bool _loadingPackages = true;
  List<AdminPromotionPackage> _packages = [];
  AdminPromotionPackage? _selectedPackage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPackages);
  }

  @override
  void dispose() {
    _listingIdController.dispose();
    super.dispose();
  }

  Future<void> _loadPackages() async {
    final packages = await ref.read(adminRepositoryProvider).fetchPromotionPackages();
    if (!mounted) return;
    setState(() {
      _packages = packages.where((p) => p.isActive).toList();
      _loadingPackages = false;
    });
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final listingId = int.tryParse(_listingIdController.text.trim());
    final package = _selectedPackage;
    if (listingId == null || package == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorUnknown)));
      return;
    }

    setState(() => _saving = true);
    try {
      final created = await ref
          .read(adminRepositoryProvider)
          .createPromotion(listingId: listingId, packageId: package.id);
      if (!mounted) return;
      Navigator.of(context).pop(created);
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
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.dashAddPromotion, style: AppTypography.section),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: l10n.dashPromotionListingIdLabel,
                controller: _listingIdController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: AppSpacing.md),
              if (_loadingPackages)
                const Center(child: CircularProgressIndicator())
              else
                AppDropdown<AdminPromotionPackage>(
                  label: l10n.dashPromotionPackageLabel,
                  value: _selectedPackage,
                  items: _packages,
                  labelBuilder: (p) => '${p.nameAr} (${p.days} - ${Money.format(p.price)})',
                  onChanged: (value) => setState(() => _selectedPackage = value),
                ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _saving ? null : _create,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.commonSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
