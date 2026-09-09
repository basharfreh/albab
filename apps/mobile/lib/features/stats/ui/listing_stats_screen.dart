import 'package:albab_core/albab_core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/stats_repository.dart';

/// UC-37 — "إحصائيات مشاهدات عقاراتي" (brief P10 item 3): a 30-day views line chart, totals
/// for views/contacts split by channel, and a per-listing breakdown. `fl_chart`, per the
/// phase's own "Do" list.
class ListingStatsScreen extends ConsumerStatefulWidget {
  const ListingStatsScreen({super.key});

  @override
  ConsumerState<ListingStatsScreen> createState() => _ListingStatsScreenState();
}

class _ListingStatsScreenState extends ConsumerState<ListingStatsScreen> {
  OwnerStats? _stats;
  List<Listing>? _perListing;
  bool _loading = true;
  Object? _error;

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
      final repo = ref.read(statsRepositoryProvider);
      final results = await Future.wait([repo.fetchOwnerStats(), repo.fetchPerListingBreakdown()]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as OwnerStats;
        _perListing = results[1] as List<Listing>;
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
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      final error = _error;
      final message = error is ApiException ? error.localizedMessage(l10n) : l10n.errorUnknown;
      body = ErrorState(message: message, onRetry: _load);
    } else {
      final stats = _stats!;
      final perListing = _perListing!;
      body = stats.totalViews == 0 && stats.totalContacts == 0
          ? EmptyState(icon: Icons.bar_chart_outlined, message: l10n.statsEmptyMessage)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(l10n.statsLast30Days, style: AppTypography.section),
                  const SizedBox(height: AppSpacing.lg),
                  _TotalsRow(stats: stats),
                  const SizedBox(height: AppSpacing.xl),
                  _ViewsChart(series: stats.series),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l10n.statsByChannelTitle, style: AppTypography.section),
                  const SizedBox(height: AppSpacing.md),
                  _ChannelRow(stats: stats, l10n: l10n),
                  const SizedBox(height: AppSpacing.xl),
                  Text(l10n.statsPerListingTitle, style: AppTypography.section),
                  const SizedBox(height: AppSpacing.md),
                  for (final listing in perListing)
                    _PerListingTile(
                      listing: listing,
                      onTap: () => context.push('/listing/${listing.id}'),
                    ),
                ],
              ),
            );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountStats)),
      body: body,
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.stats});

  final OwnerStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(child: _TotalCard(label: l10n.statsTotalViews, value: stats.totalViews)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _TotalCard(label: l10n.statsTotalContacts, value: stats.totalContacts)),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: AppTypography.display.copyWith(color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ViewsChart extends StatelessWidget {
  const _ViewsChart({required this.series});

  final List<DailyStat> series;

  @override
  Widget build(BuildContext context) {
    final maxViews = series.map((d) => d.views).fold(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 180,
      child: LineChart(
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
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.stats, required this.l10n});

  final OwnerStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ChannelCard(icon: Icons.call_outlined, label: l10n.listingCall, value: stats.byChannel.call),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ChannelCard(
            icon: Icons.chat_outlined,
            label: l10n.listingWhatsapp,
            value: stats.byChannel.whatsapp,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ChannelCard(
            icon: Icons.mail_outline,
            label: l10n.statsChannelMessage,
            value: stats.byChannel.message,
          ),
        ),
      ],
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: AppSpacing.xs),
            Text('$value', style: AppTypography.title),
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _PerListingTile extends StatelessWidget {
  const _PerListingTile({required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_outlined, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('${listing.viewsCount ?? 0}', style: AppTypography.label),
            const SizedBox(width: AppSpacing.md),
            const Icon(Icons.forum_outlined, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('${listing.contactsCount ?? 0}', style: AppTypography.label),
          ],
        ),
      ),
    );
  }
}
