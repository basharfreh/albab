import 'dart:async';

import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../discovery/data/geo_repository.dart';
import '../../discovery/data/map_filters.dart';
import '../../discovery/ui/widgets/map_search_field.dart';
import '../data/listings_repository.dart';
import 'widgets/map_pin.dart';

/// Al-Bab, Syria — the whole product is scoped to this one city (brief §1).
const _albabCenter = ll.LatLng(36.3711, 37.5169);

/// A box roughly covering the city and its immediate surroundings, used both to constrain
/// the camera (brief P6 item 1: "a bounds constraint around the city") and as the very
/// first bbox query before the map has ever moved. `LatLngBounds` is `flutter_map`'s own
/// type (not `latlong2`'s), hence the unprefixed import.
final _albabBounds = LatLngBounds(
  const ll.LatLng(36.30, 37.44),
  const ll.LatLng(36.44, 37.60),
);

String _bboxOf(LatLngBounds bounds) {
  return '${bounds.west},${bounds.south},${bounds.east},${bounds.north}';
}

enum _MapListToggle { map, list }

/// UC-10/11/14: the map home screen — markers from `GET /listings/map/`, a peek card on
/// pin tap, a search + filter + bell overlay, and a list view sharing the same filter state.
class MapHomeScreen extends ConsumerStatefulWidget {
  const MapHomeScreen({super.key});

  @override
  ConsumerState<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends ConsumerState<MapHomeScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  MapMarkersResult? _markers;
  bool _loading = true;
  Object? _error;
  int? _selectedListingId;
  _MapListToggle _toggle = _MapListToggle.map;
  bool _listEverShown = false;

  @override
  void initState() {
    super.initState();
    // Deferred a tick (same pattern as `SplashScreen`'s `restoreSession()` call): this
    // widget is itself being mounted as part of a larger build pass (go_router's own
    // `Builder`), and both mutating a provider and calling `setState` synchronously from
    // `initState` in that situation trip Riverpod's/Flutter's "modified during build" guards.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(mapFiltersProvider.notifier).setBbox(_bboxOf(_albabBounds));
      // Loaded once here, then again whenever `mapFiltersProvider` changes (see build()) —
      // this first call covers app boot, before any `onMapEvent` has fired.
      _fetchMarkers();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchMarkers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(listingsRepositoryProvider)
          .fetchMapMarkers(ref.read(mapFiltersProvider));
      if (!mounted) return;
      setState(() {
        _markers = result;
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

  /// Refetches at most once per gesture (brief P6 "Done when"): `onMapEvent` fires
  /// continuously while dragging, so only the *last* event within 400ms triggers a fetch.
  /// Only writes the new bbox into [mapFiltersProvider] — the `ref.listen` in [build] is
  /// what actually refetches, the same single trigger point every filter change (including
  /// the filter screen's own "apply") now goes through.
  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        final bounds = _mapController.camera.visibleBounds;
        ref.read(mapFiltersProvider.notifier).setBbox(_bboxOf(bounds));
      });
    }
  }

  void _selectMarker(ListingMapMarker marker) => setState(() => _selectedListingId = marker.id);

  void _openDetail(int listingId) => context.push('/listing/$listingId');

  /// Brief P7 item 5: a submitted search first tries `/geo/search/` for a *place* — if one
  /// matches, the camera moves there instead of filtering (the existing `onMapEvent` →
  /// debounce → bbox update → `ref.listen`-driven refetch path already fires from a
  /// programmatic `_mapController.move`, so nothing else here needs to trigger that).
  /// Otherwise it's a free-text property search, which sets `query` — also refetched by
  /// the same listener, not fetched directly from here.
  Future<void> _onSearchSubmitted(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      ref.read(mapFiltersProvider.notifier).setQuery(null);
      return;
    }
    var places = const <PlaceResult>[];
    try {
      places = await ref.read(geoRepositoryProvider).searchPlaces(trimmed);
    } catch (_) {
      // A dropped place search shouldn't block falling back to a text filter below.
    }
    if (!mounted) return;
    if (places.isNotEmpty) {
      final place = places.first;
      _mapController.move(ll.LatLng(place.lat, place.lng), 16);
      return;
    }
    ref.read(mapFiltersProvider.notifier).setQuery(trimmed);
  }

  void _openFilters() => context.push('/filters');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final unreadNotifications = switch (authState) {
      AuthStateAuthenticated(:final user) => user.unreadNotifications ?? 0,
      _ => 0,
    };

    // The single trigger point for every marker refetch after the initial one in
    // `initState`: a map pan (via `_onMapEvent`), a search submit, and — brief P7 item 4,
    // "applying [filters] ... updates map + list together" — the filter screen's own
    // `apply()` all just write into `mapFiltersProvider` and let this fire, rather than
    // each caller separately remembering to call `_fetchMarkers()` (which a filter-screen
    // apply, landing here from an entirely different route, previously never did).
    ref.listen(mapFiltersProvider, (previous, next) {
      if (previous != next) _fetchMarkers();
    });

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _toggle == _MapListToggle.map ? 0 : 1,
            children: [
              _buildMapArea(l10n),
              // Built lazily: an `IndexedStack` keeps every child mounted regardless of
              // which is visible, so constructing this eagerly would fire `GET /listings/`
              // on every cold start even for someone who never opens the list tab.
              if (_listEverShown)
                _ListingsListView(onOpenDetail: _openDetail)
              else
                const SizedBox.shrink(),
            ],
          ),
          _TopOverlay(
            controller: _searchController,
            onSubmitted: _onSearchSubmitted,
            onFilterTap: _openFilters,
            unreadNotifications: unreadNotifications,
            hasActiveFilters: !ref.watch(mapFiltersProvider).isDefault,
          ),
          Positioned(
            bottom: AppSpacing.xl,
            left: 0,
            right: 0,
            child: Center(child: _ListMapToggle(value: _toggle, onChanged: _setToggle)),
          ),
        ],
      ),
    );
  }

  void _setToggle(_MapListToggle value) => setState(() {
    _toggle = value;
    if (value == _MapListToggle.list) _listEverShown = true;
  });

  Widget _buildMapArea(AppLocalizations l10n) {
    if (_loading && _markers == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _markers == null) {
      final error = _error;
      final message = error is ApiException ? error.localizedMessage(l10n) : l10n.errorUnknown;
      return ErrorState(message: message, onRetry: _fetchMarkers);
    }

    final markers = _markers?.results ?? const <ListingMapMarker>[];
    ListingMapMarker? selected;
    final selectedId = _selectedListingId;
    if (selectedId != null) {
      for (final m in markers) {
        if (m.id == selectedId) {
          selected = m;
          break;
        }
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _albabCenter,
            initialZoom: 14,
            minZoom: 12,
            maxZoom: 18,
            cameraConstraint: CameraConstraint.contain(bounds: _albabBounds),
            onTap: (_, _) => setState(() => _selectedListingId = null),
            onMapEvent: _onMapEvent,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'sy.albab.mobile',
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 45,
                size: const Size(40, 40),
                // The pin widget below has its own `GestureDetector` for per-marker
                // selection — this tells the cluster layer to leave marker taps to it
                // rather than intercepting them itself (its own `onMarkerTap`/
                // `centerMarkerOnClick` are for markers with no gesture handling of
                // their own, which isn't the case here).
                markerChildBehavior: true,
                markers: [
                  for (final marker in markers)
                    Marker(
                      point: ll.LatLng(double.parse(marker.lat), double.parse(marker.lng)),
                      width: 48,
                      height: 56,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => _selectMarker(marker),
                        child: MapPin(
                          propertyType: marker.propertyType,
                          selected: marker.id == _selectedListingId,
                        ),
                      ),
                    ),
                ],
                builder: (context, clusterMarkers) =>
                    MapClusterMarker(count: clusterMarkers.length),
              ),
            ),
          ],
        ),
        if (markers.isEmpty && !_loading)
          Positioned(
            left: 0,
            right: 0,
            top: 80,
            child: Center(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: EmptyState(
                    icon: Icons.map_outlined,
                    title: l10n.mapEmptyTitle,
                    message: l10n.mapEmptyMessage,
                  ),
                ),
              ),
            ),
          ),
        if (selected case final selectedMarker?)
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xxxl + AppSpacing.xxl,
            child: _PeekCard(
              listingId: selectedMarker.id,
              onDismiss: () => setState(() => _selectedListingId = null),
              onTap: () => _openDetail(selectedMarker.id),
            ),
          ),
      ],
    );
  }
}

class _TopOverlay extends StatelessWidget {
  const _TopOverlay({
    required this.controller,
    required this.onSubmitted,
    required this.onFilterTap,
    required this.unreadNotifications,
    required this.hasActiveFilters,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilterTap;
  final int unreadNotifications;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MapSearchField(controller: controller, onSubmitted: onSubmitted),
            ),
            const SizedBox(width: AppSpacing.sm),
            _OverlayIconButton(icon: Icons.tune, showDot: hasActiveFilters, onTap: onFilterTap),
            const SizedBox(width: AppSpacing.sm),
            _OverlayIconButton(
              icon: Icons.notifications_outlined,
              count: unreadNotifications,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({required this.icon, this.showDot = false, this.count = 0, this.onTap});

  final IconData icon;
  final bool showDot;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: AppColors.textPrimary, size: 22),
              if (showDot)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                  ),
                ),
              if (count > 0)
                Positioned(top: -8, right: -8, child: AppBadge.count(count)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListMapToggle extends StatelessWidget {
  const _ListMapToggle({required this.value, required this.onChanged});

  final _MapListToggle value;
  final ValueChanged<_MapListToggle> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.navy,
      borderRadius: AppRadius.pillRadius,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToggleSegment(
              label: l10n.mapViewToggleMap,
              icon: Icons.map_outlined,
              selected: value == _MapListToggle.map,
              onTap: () => onChanged(_MapListToggle.map),
            ),
            _ToggleSegment(
              label: l10n.mapViewToggleList,
              icon: Icons.list_outlined,
              selected: value == _MapListToggle.list,
              onTap: () => onChanged(_MapListToggle.list),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.label.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// The peek card (UC-11): fetches just this one listing's card data on selection rather
/// than keeping full `Listing` objects around for every marker, which the map endpoint
/// deliberately doesn't send (brief §7: markers stay under ~120 bytes each).
class _PeekCard extends ConsumerStatefulWidget {
  const _PeekCard({required this.listingId, required this.onDismiss, required this.onTap});

  final int listingId;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  ConsumerState<_PeekCard> createState() => _PeekCardState();
}

class _PeekCardState extends ConsumerState<_PeekCard> {
  late Future<Listing> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(listingsRepositoryProvider).fetchListingDetail(widget.listingId);
  }

  @override
  void didUpdateWidget(covariant _PeekCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listingId != widget.listingId) {
      _future = ref.read(listingsRepositoryProvider).fetchListingDetail(widget.listingId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(widget.listingId),
      direction: DismissDirection.down,
      onDismissed: (_) => widget.onDismiss(),
      child: SizedBox(
        height: 110,
        child: FutureBuilder<Listing>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const ListingCardSkeleton();
            }
            return ListingCard(
              listing: snapshot.data!,
              layout: ListingCardLayout.horizontal,
              onTap: widget.onTap,
            );
          },
        ),
      ),
    );
  }
}

/// UC-14: the same active filters, `GET /listings/` instead of `/listings/map/`, infinite
/// scroll, pull-to-refresh. Not gated on the map's own bbox — a fresh page load takes the
/// filters as they stand rather than "search this area", matching brief P6 item 5's plain
/// reading (P7 nuances "search this area" further once the filter sheet exists).
class _ListingsListView extends ConsumerStatefulWidget {
  const _ListingsListView({required this.onOpenDetail});

  final ValueChanged<int> onOpenDetail;

  @override
  ConsumerState<_ListingsListView> createState() => _ListingsListViewState();
}

class _ListingsListViewState extends ConsumerState<_ListingsListView> {
  final _scrollController = ScrollController();
  final _items = <Listing>[];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Deferred a tick — see `_MapHomeScreenState.initState`'s comment: this widget is
    // itself mounted during a build pass (the toggle's `setState`), so `_load`'s own
    // `setState` calls need to land after that pass finishes, not inside it.
    Future.microtask(() {
      if (mounted) _load(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load({required bool reset}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _page = 1;
        _hasMore = true;
      }
    });
    try {
      final filters = ref.read(mapFiltersProvider);
      final result = await ref
          .read(listingsRepositoryProvider)
          .fetchListings(filters, page: _page);
      if (!mounted) return;
      setState(() {
        _items.addAll(result.results);
        _hasMore = result.next != null;
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

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _page += 1;
    await _load(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Every real assignment to `mapFiltersProvider`'s state is a genuine change (the map's
    // bbox settling, or a search submit) — `MapFilters` doesn't override `==`, but that's
    // fine here since the notifier only ever reassigns state from an actual mutator call,
    // never as a side effect of rebuilding.
    ref.listen(mapFiltersProvider, (previous, next) {
      if (previous != next) _load(reset: true);
    });

    if (_items.isEmpty && _loading) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          80,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => const ListingCardSkeleton(),
      );
    }
    if (_items.isEmpty && _error != null) {
      final error = _error;
      final message = error is ApiException ? error.localizedMessage(l10n) : l10n.errorUnknown;
      return ErrorState(message: message, onRetry: () => _load(reset: true));
    }
    if (_items.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: l10n.mapEmptyTitle,
        message: l10n.mapEmptyMessage,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          80,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final listing = _items[index];
          return ListingCard(listing: listing, onTap: () => widget.onOpenDetail(listing.id));
        },
      ),
    );
  }
}
