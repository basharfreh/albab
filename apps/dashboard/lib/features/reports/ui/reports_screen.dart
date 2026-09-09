import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/data/admin_models.dart';
import '../../admin/data/admin_repository.dart';
import '../data/csv_downloader.dart';

/// التقارير (UC-58, brief P11 item 7): the abuse-report queue (resolve/dismiss collapse to
/// the backend's one `close` action — see docs/PROGRESS.md) plus CSV export of listings and
/// users. Export reuses the same `/admin/listings/` and `/admin/users/` calls the
/// العقارات/المستخدمين screens already use (up to 50 rows each, same page-size cap those
/// screens have — not a full server-side export), rather than adding new backend endpoints.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool? _openOnly = true;
  bool _loading = true;
  Object? _error;
  List<AdminReport> _reports = [];
  final Set<int> _acting = {};
  bool _exporting = false;

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
      final status = switch (_openOnly) {
        true => 'open',
        false => 'closed',
        null => null,
      };
      final reports = await ref.read(adminRepositoryProvider).fetchReports(status: status);
      if (!mounted) return;
      setState(() {
        _reports = reports;
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

  Future<void> _close(AdminReport report) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _acting.add(report.id));
    try {
      await ref.read(adminRepositoryProvider).closeReport(report.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dashReportClosed)));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
    } finally {
      if (mounted) setState(() => _acting.remove(report.id));
    }
  }

  Future<void> _exportListings() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _exporting = true);
    try {
      final listings = await ref
          .read(adminRepositoryProvider)
          .fetchAdminListings(pageSize: 50);
      _downloadCsv(
        filename: 'listings.csv',
        headers: const [
          'id',
          'title',
          'status',
          'purpose',
          'property_type',
          'price',
          'neighborhood',
          'views',
          'created_at',
        ],
        rows: [
          for (final listing in listings)
            [
              '${listing.id}',
              listing.title,
              listing.status?.wireValue ?? '',
              listing.purpose.wireValue,
              listing.propertyType.wireValue,
              listing.price ?? '',
              listing.neighborhoodName ?? '',
              '${listing.viewsCount ?? 0}',
              listing.createdAt?.toIso8601String() ?? '',
            ],
        ],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dashExportDone)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportUsers() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _exporting = true);
    try {
      final users = await ref.read(adminRepositoryProvider).fetchUsers();
      _downloadCsv(
        filename: 'users.csv',
        headers: const ['id', 'name', 'phone', 'role', 'status', 'created_at'],
        rows: [
          for (final user in users)
            [
              '${user.id}',
              user.name,
              user.phone ?? '',
              user.role.wireValue,
              (user.isBlocked ?? false) ? 'blocked' : 'active',
              user.createdAt?.toIso8601String() ?? '',
            ],
        ],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dashExportDone)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.localizedMessage(l10n))));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _downloadCsv({
    required String filename,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    String esc(String v) => '"${v.replaceAll('"', '""')}"';
    final buffer = StringBuffer()..writeln(headers.map(esc).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(esc).join(','));
    }
    downloadCsv(filename: filename, content: buffer.toString());
  }

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
            Text(l10n.dashNavReports, style: AppTypography.title),
            SizedBox(
              width: 200,
              child: AppDropdown<bool?>(
                label: l10n.dashStatusFilterLabel,
                value: _openOnly,
                items: const [null, true, false],
                labelBuilder: (value) => switch (value) {
                  null => l10n.dashStatusFilterAll,
                  true => l10n.dashReportStatusOpen,
                  false => l10n.dashReportStatusClosed,
                },
                onChanged: (value) {
                  setState(() => _openOnly = value);
                  _load();
                },
              ),
            ),
            OutlinedButton.icon(
              onPressed: _exporting ? null : _exportListings,
              icon: const Icon(Icons.download_outlined, size: AppIconSizes.inline),
              label: Text(l10n.dashExportListingsCsv),
            ),
            OutlinedButton.icon(
              onPressed: _exporting ? null : _exportUsers,
              icon: const Icon(Icons.download_outlined, size: AppIconSizes.inline),
              label: Text(l10n.dashExportUsersCsv),
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
            if (_reports.isEmpty) {
              return EmptyState(
                icon: Icons.flag_outlined,
                title: l10n.dashEmptyReportsTitle,
                message: l10n.dashEmptyReportsMessage,
              );
            }
            return Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l10n.dashColListing)),
                    DataColumn(label: Text(l10n.dashColReporter)),
                    DataColumn(label: Text(l10n.dashColReason)),
                    DataColumn(label: Text(l10n.dashColNote)),
                    DataColumn(label: Text(l10n.dashColDate)),
                    DataColumn(label: Text(l10n.dashColStatus)),
                    DataColumn(label: Text(l10n.dashColActions)),
                  ],
                  rows: [
                    for (final report in _reports)
                      DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Text(report.listingTitle, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          DataCell(Text(report.reporterName)),
                          DataCell(Text(report.reason)),
                          DataCell(
                            SizedBox(
                              width: 200,
                              child: Text(report.note, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          DataCell(Text(RelativeTime.format(l10n, report.createdAt))),
                          DataCell(_ReportStatusChip(isOpen: report.isOpen, l10n: l10n)),
                          DataCell(
                            _acting.contains(report.id)
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : report.isOpen
                                ? TextButton(
                                    onPressed: () => _close(report),
                                    child: Text(l10n.dashReportClose),
                                  )
                                : const SizedBox.shrink(),
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

class _ReportStatusChip extends StatelessWidget {
  const _ReportStatusChip({required this.isOpen, required this.l10n});

  final bool isOpen;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.warning : AppColors.textSecondary;
    return Chip(
      label: Text(isOpen ? l10n.dashReportStatusOpen : l10n.dashReportStatusClosed),
      labelStyle: AppTypography.caption.copyWith(color: color),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}
