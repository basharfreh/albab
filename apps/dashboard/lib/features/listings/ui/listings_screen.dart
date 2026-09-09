import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/data/admin_repository.dart';

/// العقارات (UC-54, brief P11 item 4). This slice covers the moderation core — a
/// status-filterable table with approve/reject acting per row — not yet the full brief
/// (detail drawer with gallery/map/owner/history, bulk selection, server-side search); see
/// docs/PROGRESS.md for what's left.
class ListingsScreen extends ConsumerStatefulWidget {
  const ListingsScreen({super.key});

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen> {
  ListingStatus? _statusFilter = ListingStatus.pending;
  bool _loading = true;
  Object? _error;
  List<Listing> _listings = [];
  final Set<int> _acting = {};

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
      final listings = await ref
          .read(adminRepositoryProvider)
          .fetchAdminListings(status: _statusFilter?.wireValue, pageSize: 50);
      if (!mounted) return;
      setState(() {
        _listings = listings;
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

  Future<void> _approve(Listing listing) async {
    setState(() => _acting.add(listing.id));
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(adminRepositoryProvider).approveListing(listing.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dashApproved)));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
    } finally {
      if (mounted) setState(() => _acting.remove(listing.id));
    }
  }

  Future<void> _reject(Listing listing) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dashReject),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(labelText: l10n.dashRejectReasonLabel),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text.trim()),
            child: Text(l10n.dashReject),
          ),
        ],
      ),
    );
    if (reason == null) return;
    if (reason.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.dashRejectReasonRequired)));
      return;
    }

    setState(() => _acting.add(listing.id));
    try {
      await ref.read(adminRepositoryProvider).rejectListing(listing.id, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dashRejected)));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
    } finally {
      if (mounted) setState(() => _acting.remove(listing.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.dashNavListings, style: AppTypography.title),
            SizedBox(
              width: 220,
              child: AppDropdown<ListingStatus?>(
                label: l10n.dashStatusFilterLabel,
                value: _statusFilter,
                items: [null, ...ListingStatus.values],
                labelBuilder: (status) =>
                    status == null ? l10n.dashStatusFilterAll : status.label(l10n),
                onChanged: (value) {
                  setState(() => _statusFilter = value);
                  _load();
                },
              ),
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
            if (_listings.isEmpty) {
              return EmptyState(
                icon: Icons.home_work_outlined,
                title: l10n.dashEmptyListingsTitle,
                message: l10n.dashEmptyListingsMessage,
              );
            }
            return Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l10n.dashColTitle)),
                    DataColumn(label: Text(l10n.dashColNeighborhood)),
                    DataColumn(label: Text(l10n.filterPropertyType)),
                    DataColumn(label: Text(l10n.dashColPrice)),
                    DataColumn(label: Text(l10n.dashColStatus)),
                    DataColumn(label: Text(l10n.dashColActions)),
                  ],
                  rows: [
                    for (final listing in _listings)
                      DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 220,
                              child: Text(listing.title, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          DataCell(Text(listing.neighborhoodName ?? '')),
                          DataCell(Text(listing.propertyType.label(l10n))),
                          DataCell(
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                listing.price == null ? '' : Money.format(listing.price!),
                              ),
                            ),
                          ),
                          DataCell(_StatusChip(status: listing.status, l10n: l10n)),
                          DataCell(
                            _acting.contains(listing.id)
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (listing.status == ListingStatus.pending) ...[
                                        TextButton(
                                          onPressed: () => _approve(listing),
                                          child: Text(l10n.dashApprove),
                                        ),
                                        TextButton(
                                          onPressed: () => _reject(listing),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.danger,
                                          ),
                                          child: Text(l10n.dashReject),
                                        ),
                                      ],
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.l10n});

  final ListingStatus? status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final value = status;
    if (value == null) return const SizedBox.shrink();
    return Chip(
      label: Text(value.label(l10n)),
      avatar: Icon(value.icon, size: 16, color: value.color),
      labelStyle: AppTypography.caption.copyWith(color: value.color),
      side: BorderSide(color: value.color.withValues(alpha: 0.4)),
    );
  }
}
