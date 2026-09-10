import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/data/admin_models.dart';
import '../../admin/data/admin_repository.dart';

enum _SettingsSection { neighborhoods, quotas, pages }

/// الإعدادات (UC-59, brief P11 item 8): three sections — الأحياء (neighborhoods CRUD),
/// الحصص (per-role active-listing quotas), المحتوى الثابت (generic static pages). Unlike
/// المستخدمين/التقارير, none of this had any backend endpoint before this session — see
/// docs/PROGRESS.md for the new `/admin/neighborhoods/`, `/admin/settings/quotas/`,
/// `/admin/settings/pages/` routes.
///
/// **Simplification from the brief**: "center point picked on a small map" (brief P11 item
/// 8) is plain lat/lng text fields here, not an interactive map picker — `apps/dashboard`
/// has no map dependency yet (mobile's listing wizard does, via a package not pulled into
/// this app), and adding one for a single admin-only form felt like the wrong place to
/// introduce it. Flagged, not silently downgraded.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsSection _section = _SettingsSection.neighborhoods;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.dashNavSettings, style: AppTypography.title),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: Text(l10n.dashSettingsNeighborhoods),
              selected: _section == _SettingsSection.neighborhoods,
              onSelected: (_) => setState(() => _section = _SettingsSection.neighborhoods),
            ),
            ChoiceChip(
              label: Text(l10n.dashSettingsQuotas),
              selected: _section == _SettingsSection.quotas,
              onSelected: (_) => setState(() => _section = _SettingsSection.quotas),
            ),
            ChoiceChip(
              label: Text(l10n.dashSettingsPages),
              selected: _section == _SettingsSection.pages,
              onSelected: (_) => setState(() => _section = _SettingsSection.pages),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        switch (_section) {
          _SettingsSection.neighborhoods => const _NeighborhoodsSection(),
          _SettingsSection.quotas => const _QuotasSection(),
          _SettingsSection.pages => const _StaticPagesSection(),
        },
      ],
    );
  }
}

class _NeighborhoodsSection extends ConsumerStatefulWidget {
  const _NeighborhoodsSection();

  @override
  ConsumerState<_NeighborhoodsSection> createState() => _NeighborhoodsSectionState();
}

class _NeighborhoodsSectionState extends ConsumerState<_NeighborhoodsSection> {
  bool _loading = true;
  Object? _error;
  List<AdminNeighborhood> _neighborhoods = [];

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
      final neighborhoods = await ref.read(adminRepositoryProvider).fetchAdminNeighborhoods();
      if (!mounted) return;
      setState(() {
        _neighborhoods = neighborhoods;
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

  Future<void> _openDialog({AdminNeighborhood? existing}) async {
    final saved = await showDialog<AdminNeighborhood>(
      context: context,
      builder: (context) => _NeighborhoodDialog(existing: existing),
    );
    if (saved == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.dashNeighborhoodSaved)));
    await _load();
  }

  Future<void> _delete(AdminNeighborhood neighborhood) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dashConfirmDeleteTitle),
        content: Text(l10n.dashConfirmDeleteNeighborhoodMessage),
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
      await ref.read(adminRepositoryProvider).deleteNeighborhood(neighborhood.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.dashNeighborhoodDeleted)));
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
            label: Text(l10n.dashAddNeighborhood),
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
            if (_neighborhoods.isEmpty) {
              return EmptyState(
                icon: Icons.map_outlined,
                title: l10n.dashEmptyNeighborhoodsTitle,
                message: l10n.dashEmptyNeighborhoodsMessage,
              );
            }
            return Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l10n.dashColNameAr)),
                    DataColumn(label: Text(l10n.dashColNameEn)),
                    DataColumn(label: Text(l10n.dashColSlug)),
                    DataColumn(label: Text(l10n.dashColLat)),
                    DataColumn(label: Text(l10n.dashColLng)),
                    DataColumn(label: Text(l10n.dashColActive)),
                    DataColumn(label: Text(l10n.dashColActions)),
                  ],
                  rows: [
                    for (final neighborhood in _neighborhoods)
                      DataRow(
                        cells: [
                          DataCell(Text(neighborhood.nameAr)),
                          DataCell(Text(neighborhood.nameEn)),
                          DataCell(Text(neighborhood.slug)),
                          DataCell(
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(neighborhood.centerLat),
                            ),
                          ),
                          DataCell(
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(neighborhood.centerLng),
                            ),
                          ),
                          DataCell(
                            Chip(
                              label: Text(
                                neighborhood.isActive ? l10n.dashActive : l10n.dashInactive,
                              ),
                              labelStyle: AppTypography.caption.copyWith(
                                color: neighborhood.isActive
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
                                  onPressed: () => _openDialog(existing: neighborhood),
                                  child: Text(l10n.commonEdit),
                                ),
                                TextButton(
                                  onPressed: () => _delete(neighborhood),
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

class _NeighborhoodDialog extends ConsumerStatefulWidget {
  const _NeighborhoodDialog({this.existing});

  final AdminNeighborhood? existing;

  @override
  ConsumerState<_NeighborhoodDialog> createState() => _NeighborhoodDialogState();
}

class _NeighborhoodDialogState extends ConsumerState<_NeighborhoodDialog> {
  late final _nameArController = TextEditingController(text: widget.existing?.nameAr);
  late final _nameEnController = TextEditingController(text: widget.existing?.nameEn);
  late final _slugController = TextEditingController(text: widget.existing?.slug);
  late final _latController = TextEditingController(text: widget.existing?.centerLat);
  late final _lngController = TextEditingController(text: widget.existing?.centerLng);
  late bool _isActive = widget.existing?.isActive ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _slugController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    final draft = AdminNeighborhood(
      id: widget.existing?.id ?? 0,
      nameAr: _nameArController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      slug: _slugController.text.trim(),
      centerLat: _latController.text.trim(),
      centerLng: _lngController.text.trim(),
      isActive: _isActive,
      sortOrder: widget.existing?.sortOrder ?? 0,
    );
    try {
      final repo = ref.read(adminRepositoryProvider);
      final saved = widget.existing == null
          ? await repo.createNeighborhood(draft)
          : await repo.updateNeighborhood(draft);
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
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEdit ? l10n.dashEditNeighborhood : l10n.dashAddNeighborhood,
                  style: AppTypography.section,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(label: l10n.dashNeighborhoodNameArLabel, controller: _nameArController),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: l10n.dashNeighborhoodNameEnLabel, controller: _nameEnController),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: l10n.dashNeighborhoodSlugLabel, controller: _slugController),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.dashNeighborhoodLatLabel,
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.dashNeighborhoodLngLabel,
                  controller: _lngController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value ?? true),
                  title: Text(l10n.dashNeighborhoodActiveLabel),
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

class _QuotasSection extends ConsumerStatefulWidget {
  const _QuotasSection();

  @override
  ConsumerState<_QuotasSection> createState() => _QuotasSectionState();
}

class _QuotasSectionState extends ConsumerState<_QuotasSection> {
  bool _loading = true;
  bool _saving = false;
  Object? _error;
  final _seekerController = TextEditingController();
  final _ownerController = TextEditingController();
  final _agencyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _seekerController.dispose();
    _ownerController.dispose();
    _agencyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final quotas = await ref.read(adminRepositoryProvider).fetchQuotaSettings();
      if (!mounted) return;
      _seekerController.text = '${quotas.seeker}';
      _ownerController.text = '${quotas.owner}';
      _agencyController.text = '${quotas.agency}';
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final seeker = int.tryParse(_seekerController.text.trim());
    final owner = int.tryParse(_ownerController.text.trim());
    final agency = int.tryParse(_agencyController.text.trim());
    if (seeker == null || owner == null || agency == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorUnknown)));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateQuotaSettings(QuotaSettings(seeker: seeker, owner: owner, agency: agency));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dashQuotasSaved)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final error = _error;
    if (error != null) {
      final message = error is ApiException ? error.localizedMessage(l10n) : l10n.errorUnknown;
      return ErrorState(message: message, onRetry: _load);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.dashQuotasHint,
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: l10n.dashQuotaSeeker,
                controller: _seekerController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.dashQuotaOwner,
                controller: _ownerController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.dashQuotaAgency,
                controller: _agencyController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.commonSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaticPagesSection extends ConsumerStatefulWidget {
  const _StaticPagesSection();

  @override
  ConsumerState<_StaticPagesSection> createState() => _StaticPagesSectionState();
}

class _StaticPagesSectionState extends ConsumerState<_StaticPagesSection> {
  bool _loading = true;
  Object? _error;
  List<AdminStaticPage> _pages = [];

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
      final pages = await ref.read(adminRepositoryProvider).fetchStaticPages();
      if (!mounted) return;
      setState(() {
        _pages = pages;
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

  Future<void> _openDialog({AdminStaticPage? existing}) async {
    final saved = await showDialog<AdminStaticPage>(
      context: context,
      builder: (context) => _StaticPageDialog(existing: existing),
    );
    if (saved == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dashPageSaved)));
    await _load();
  }

  Future<void> _delete(AdminStaticPage page) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dashConfirmDeleteTitle),
        content: Text(page.titleAr),
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
      await ref.read(adminRepositoryProvider).deleteStaticPage(page.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dashPageDeleted)));
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
            label: Text(l10n.dashAddPage),
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
            if (_pages.isEmpty) {
              return EmptyState(
                icon: Icons.article_outlined,
                title: l10n.dashEmptyPagesTitle,
                message: l10n.dashEmptyPagesMessage,
              );
            }
            return Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l10n.dashColSlug)),
                    DataColumn(label: Text(l10n.dashPageTitleArLabel)),
                    DataColumn(label: Text(l10n.dashColActions)),
                  ],
                  rows: [
                    for (final page in _pages)
                      DataRow(
                        cells: [
                          DataCell(Text(page.slug)),
                          DataCell(Text(page.titleAr)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _openDialog(existing: page),
                                  child: Text(l10n.commonEdit),
                                ),
                                TextButton(
                                  onPressed: () => _delete(page),
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

class _StaticPageDialog extends ConsumerStatefulWidget {
  const _StaticPageDialog({this.existing});

  final AdminStaticPage? existing;

  @override
  ConsumerState<_StaticPageDialog> createState() => _StaticPageDialogState();
}

class _StaticPageDialogState extends ConsumerState<_StaticPageDialog> {
  late final _slugController = TextEditingController(text: widget.existing?.slug);
  late final _titleArController = TextEditingController(text: widget.existing?.titleAr);
  late final _titleEnController = TextEditingController(text: widget.existing?.titleEn);
  late final _bodyArController = TextEditingController(text: widget.existing?.bodyAr);
  late final _bodyEnController = TextEditingController(text: widget.existing?.bodyEn);
  bool _saving = false;

  @override
  void dispose() {
    _slugController.dispose();
    _titleArController.dispose();
    _titleEnController.dispose();
    _bodyArController.dispose();
    _bodyEnController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    final draft = AdminStaticPage(
      id: widget.existing?.id ?? 0,
      slug: _slugController.text.trim(),
      titleAr: _titleArController.text.trim(),
      titleEn: _titleEnController.text.trim(),
      bodyAr: _bodyArController.text.trim(),
      bodyEn: _bodyEnController.text.trim(),
    );
    try {
      final repo = ref.read(adminRepositoryProvider);
      final saved = widget.existing == null
          ? await repo.createStaticPage(draft)
          : await repo.updateStaticPage(draft);
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
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEdit ? l10n.dashEditPage : l10n.dashAddPage, style: AppTypography.section),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: l10n.dashPageSlugLabel,
                  controller: _slugController,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: l10n.dashPageTitleArLabel, controller: _titleArController),
                const SizedBox(height: AppSpacing.md),
                AppTextField(label: l10n.dashPageTitleEnLabel, controller: _titleEnController),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.dashPageBodyArLabel,
                  controller: _bodyArController,
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.dashPageBodyEnLabel,
                  controller: _bodyEnController,
                  maxLines: 4,
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
