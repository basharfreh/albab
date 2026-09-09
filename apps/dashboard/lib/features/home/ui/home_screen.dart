import 'package:albab_core/albab_core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../admin/data/admin_models.dart';
import '../../admin/data/admin_repository.dart';

/// الرئيسية (UC-50…UC-53, brief P11 item 3): four KPI cards, the 30-day visits chart, the
/// by-type pie, and the latest/most-viewed tables — the last two both read
/// `AdminRepository.fetchAdminListings` with a different `ordering` (see that method's doc).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _loading = true;
  Object? _error;
  AdminKpis? _kpis;
  List<VisitsPoint>? _visits;
  List<ByTypeSlice>? _byType;
  List<Listing>? _latest;
  List<Listing>? _mostViewed;

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
      final repo = ref.read(adminRepositoryProvider);
      final results = await Future.wait([
        repo.fetchKpis(),
        repo.fetchVisits(days: 30),
        repo.fetchByType(),
        repo.fetchAdminListings(status: 'published', ordering: '-created_at', pageSize: 5),
        repo.fetchAdminListings(status: 'published', ordering: '-views_count', pageSize: 5),
      ]);
      if (!mounted) return;
      setState(() {
        _kpis = results[0] as AdminKpis;
        _visits = results[1] as List<VisitsPoint>;
        _byType = results[2] as List<ByTypeSlice>;
        _latest = results[3] as List<Listing>;
        _mostViewed = results[4] as List<Listing>;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _error;
    if (error != null) {
      final message = error is ApiException ? error.localizedMessage(l10n) : l10n.errorUnknown;
      return ErrorState(message: message, onRetry: _load);
    }

    // A `Column`, not a `ListView` — this screen is already inside the shell's own
    // `SingleChildScrollView` (`DashboardShell`), and a scrollable viewport nested inside
    // another unbounded-height scrollable throws ("Vertical viewport was given unbounded
    // height").
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KpiRow(kpis: _kpis!, l10n: l10n),
        const SizedBox(height: AppSpacing.xxl),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            final visitsCard = _ChartCard(
              title: l10n.dashVisitsLast30Days,
              child: _VisitsChart(series: _visits!),
            );
            final byTypeCard = _ChartCard(
              title: l10n.dashListingsByType,
              child: _ByTypePie(slices: _byType!),
            );
            if (!wide) {
              return Column(
                children: [visitsCard, const SizedBox(height: AppSpacing.xxl), byTypeCard],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: visitsCard),
                const SizedBox(width: AppSpacing.xxl),
                Expanded(child: byTypeCard),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
        _ListingsTableCard(title: l10n.dashLatestListings, listings: _latest!, showViews: false),
        const SizedBox(height: AppSpacing.xxl),
        _ListingsTableCard(title: l10n.dashMostViewed, listings: _mostViewed!, showViews: true),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.kpis, required this.l10n});

  final AdminKpis kpis;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard(label: l10n.dashKpiTotalUsers, kpi: kpis.totalUsers, l10n: l10n),
      _KpiCard(label: l10n.dashKpiTotalListings, kpi: kpis.totalListings, l10n: l10n),
      _KpiCard(label: l10n.dashKpiForSale, kpi: kpis.forSale, l10n: l10n),
      _KpiCard(label: l10n.dashKpiForRent, kpi: kpis.forRent, l10n: l10n),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 560 ? 2 : 1);
        final cardWidth =
            (constraints.maxWidth - AppSpacing.lg * (perRow - 1)) / perRow;
        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: [for (final card in cards) SizedBox(width: cardWidth, child: card)],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.kpi, required this.l10n});

  final String label;
  final AdminKpi kpi;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Text('${kpi.total}', style: AppTypography.display),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.dashKpiDelta(kpi.delta30d),
              style: AppTypography.caption.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.section),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(height: 220, child: child),
          ],
        ),
      ),
    );
  }
}

class _VisitsChart extends StatelessWidget {
  const _VisitsChart({required this.series});

  final List<VisitsPoint> series;

  @override
  Widget build(BuildContext context) {
    final maxViews = series.map((d) => d.views).fold(0, (a, b) => a > b ? a : b);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxViews == 0 ? 1 : maxViews * 1.2,
        gridData: const FlGridData(drawVerticalLine: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < series.length; i++)
                FlSpot(i.toDouble(), series[i].views.toDouble()),
            ],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: AppColors.primaryTint),
          ),
        ],
      ),
    );
  }
}

class _ByTypePie extends StatelessWidget {
  const _ByTypePie({required this.slices});

  final List<ByTypeSlice> slices;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (slices.isEmpty) {
      return Center(
        child: Text(
          l10n.emptyStateDefaultTitle,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 32,
              sections: [
                for (final slice in slices)
                  PieChartSectionData(
                    value: slice.count.toDouble(),
                    color: slice.propertyType.pinColor,
                    title: '${slice.count}',
                    titleStyle: AppTypography.caption.copyWith(color: AppColors.surface),
                    radius: 48,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final slice in slices)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: slice.propertyType.pinColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(slice.propertyType.label(l10n), style: AppTypography.caption),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ListingsTableCard extends StatelessWidget {
  const _ListingsTableCard({required this.title, required this.listings, required this.showViews});

  final String title;
  final List<Listing> listings;
  final bool showViews;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTypography.section),
                TextButton(
                  onPressed: () => context.go('/listings'),
                  child: Text(l10n.commonViewAll),
                ),
              ],
            ),
            if (listings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  l10n.dashEmptyListingsTitle,
                  style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l10n.dashColTitle)),
                    DataColumn(label: Text(l10n.dashColNeighborhood)),
                    DataColumn(label: Text(l10n.dashColPrice)),
                    if (showViews) DataColumn(label: Text(l10n.dashColViews)),
                  ],
                  rows: [
                    for (final listing in listings)
                      DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 260,
                              child: Text(listing.title, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          DataCell(Text(listing.neighborhoodName ?? '')),
                          DataCell(
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                listing.price == null ? '' : Money.format(listing.price!),
                              ),
                            ),
                          ),
                          if (showViews) DataCell(Text('${listing.viewsCount ?? 0}')),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
