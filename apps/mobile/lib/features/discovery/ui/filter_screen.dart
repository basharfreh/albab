import 'dart:async';

import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../map/data/listings_repository.dart';
import '../data/map_filters.dart';
import 'widgets/bedrooms_selector.dart';
import 'widgets/neighborhood_dropdown.dart';
import 'widgets/purpose_selector.dart';
import 'widgets/range_filter_section.dart';

final _neighborhoodsProvider = FutureProvider.autoDispose<List<Neighborhood>>(
  (ref) => ref.read(listingsRepositoryProvider).fetchNeighborhoods(),
);

// Reasonable bounds for the sliders' visual range (brief §7's seed data: $15k–$250k
// prices, typical Al-Bab residential/commercial areas). Typing a value past either end
// still works — the number field isn't clamped, only the slider's own thumb is.
const _priceMin = 0.0;
const _priceMax = 300000.0;
const _areaMin = 0.0;
const _areaMax = 500.0;

/// UC-13: the filter screen. Works on a local draft [MapFilters] — seeded from
/// [mapFiltersProvider]'s current state so `bbox`/`query` (owned by the map screen, not
/// this one) carry through untouched — and only commits to the shared provider when
/// "عرض النتائج" is tapped. This is deliberate: committing on every slider tick would
/// refetch the map/list mid-drag, which brief P6's own "Done when" already ruled out for
/// map panning and applies equally here.
class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({super.key});

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  late MapFilters _draft;
  Timer? _debounce;
  int? _count;
  bool _countLoading = true;
  int _resetTick = 0;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(mapFiltersProvider);
    _fetchCount(immediate: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Brief P7 item 3: debounce 350ms; "while in flight, keep the last count ... never
  /// blank the number" — [_count] is only ever replaced by a new value, never cleared.
  void _fetchCount({bool immediate = false}) {
    _debounce?.cancel();
    Future<void> run() async {
      setState(() => _countLoading = true);
      try {
        final count = await ref.read(listingsRepositoryProvider).fetchResultsCount(_draft);
        if (!mounted) return;
        setState(() {
          _count = count;
          _countLoading = false;
        });
      } catch (_) {
        // A dropped live-count request shouldn't block filtering — the button falls back
        // to the last known count (or 0 pre-first-response) and stays tappable.
        if (!mounted) return;
        setState(() => _countLoading = false);
      }
    }

    if (immediate) {
      run();
    } else {
      _debounce = Timer(const Duration(milliseconds: 350), run);
    }
  }

  void _update(MapFilters Function(MapFilters draft) mutate) {
    setState(() => _draft = mutate(_draft));
    _fetchCount();
  }

  void _reset() {
    setState(() {
      _draft = MapFilters(bbox: _draft.bbox, query: _draft.query);
      _resetTick++;
    });
    _fetchCount(immediate: true);
  }

  void _apply() {
    ref.read(mapFiltersProvider.notifier).apply(_draft);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final neighborhoodsAsync = ref.watch(_neighborhoodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.filterTitle),
        actions: [TextButton(onPressed: _reset, child: Text(l10n.filterReset))],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            key: ValueKey(_resetTick),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PurposeSelector(
                value: _draft.purpose,
                onChanged: (value) => _update((f) => f.copyWith(purpose: () => value)),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppDropdown<PropertyType?>(
                label: l10n.filterPropertyType,
                value: _draft.propertyType,
                items: [null, ...PropertyType.values],
                labelBuilder: (v) => v == null ? l10n.filterAll : v.label(l10n),
                onChanged: (value) => _update((f) => f.copyWith(propertyType: () => value)),
              ),
              const SizedBox(height: AppSpacing.lg),
              NeighborhoodDropdown(
                async: neighborhoodsAsync,
                value: _draft.neighborhoodId,
                onChanged: (value) => _update((f) => f.copyWith(neighborhoodId: () => value)),
              ),
              const SizedBox(height: AppSpacing.xl),
              RangeFilterSection(
                key: ValueKey('price-$_resetTick'),
                title: l10n.filterPrice,
                min: _priceMin,
                max: _priceMax,
                divisions: 60,
                initialMin: _draft.priceMin,
                initialMax: _draft.priceMax,
                labelBuilder: (v) => Money.format(v.toStringAsFixed(0)),
                onMinChanged: (value) => _update((f) => f.copyWith(priceMin: () => value)),
                onMaxChanged: (value) => _update((f) => f.copyWith(priceMax: () => value)),
              ),
              const SizedBox(height: AppSpacing.xl),
              RangeFilterSection(
                key: ValueKey('area-$_resetTick'),
                title: l10n.filterArea,
                min: _areaMin,
                max: _areaMax,
                divisions: 50,
                initialMin: _draft.areaMin,
                initialMax: _draft.areaMax,
                labelBuilder: (v) => Area.format(l10n, v),
                onMinChanged: (value) => _update((f) => f.copyWith(areaMin: () => value)),
                onMaxChanged: (value) => _update((f) => f.copyWith(areaMax: () => value)),
              ),
              const SizedBox(height: AppSpacing.xl),
              BedroomsSelector(
                value: _draft.bedrooms,
                onChanged: (value) => _update((f) => f.copyWith(bedrooms: () => value)),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _ApplyButton(
            label: l10n.filterShowResults(_count ?? 0),
            loading: _countLoading,
            onPressed: _apply,
          ),
        ),
      ),
    );
  }
}

/// A [PrimaryButton]-styled apply button with an inline spinner that sits *beside* the
/// label rather than replacing it — `PrimaryButton.isLoading` swaps the whole label out,
/// which would blank the live count brief P7 item 3 explicitly says must never go blank.
class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.label, required this.loading, required this.onPressed});

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (loading) ...[
            const SizedBox(width: AppSpacing.sm),
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.surface),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
