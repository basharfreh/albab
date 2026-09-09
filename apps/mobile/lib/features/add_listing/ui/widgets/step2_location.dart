import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../discovery/data/geo_repository.dart';
import '../../../map/data/listings_repository.dart';
import '../../../map/ui/widgets/map_pin.dart';
import '../../data/add_listing_repository.dart';
import '../../data/wizard_draft.dart';
import 'wizard_neighborhood_field.dart';

/// Al-Bab, Syria — same center `MapHomeScreen` uses (brief §1: the whole product is one
/// city). Redefined here rather than imported: `MapHomeScreen`'s constant is file-private,
/// and sharing one literal coordinate pair isn't worth a new shared-constants file.
const _albabCenter = ll.LatLng(36.3711, 37.5169);

final _wizardNeighborhoodsProvider =
    FutureProvider.autoDispose<List<Neighborhood>>(
      (ref) => ref.read(listingsRepositoryProvider).fetchNeighborhoods(),
    );

/// Brief P9 item 3 — the location picker: a fixed center pin over a draggable map, place
/// search, and on confirm a `GET /geo/reverse/` call that fills an editable neighborhood
/// dropdown plus an optional landmark field. Every drag after a confirmation un-confirms
/// (the map is the source of truth; a stale neighborhood/landmark pair for a since-moved
/// point would be wrong), so "تأكيد الموقع" always reflects the pin's current resting spot.
class Step2Location extends ConsumerStatefulWidget {
  const Step2Location({super.key});

  @override
  ConsumerState<Step2Location> createState() => _Step2LocationState();
}

class _Step2LocationState extends ConsumerState<Step2Location> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  late final TextEditingController _landmarkController;

  late ll.LatLng _center;
  bool _confirmed = false;
  bool _confirming = false;
  List<PlaceResult> _searchResults = [];
  String? _searchedPlaceName;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(wizardDraftProvider);
    _center = draft.hasLocation
        ? ll.LatLng(draft.lat!, draft.lng!)
        : _albabCenter;
    _confirmed = draft.hasLocation;
    _landmarkController = TextEditingController(text: draft.landmark);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd || event is MapEventMove) {
      final newCenter = event.camera.center;
      setState(() {
        _center = newCenter;
        _confirmed = false;
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      final results = await ref.read(geoRepositoryProvider).searchPlaces(query);
      if (!mounted) return;
      setState(() => _searchResults = results);
    } on ApiException {
      if (!mounted) return;
      setState(() => _searchResults = []);
    }
  }

  void _selectPlace(PlaceResult place) {
    _searchedPlaceName = place.displayName.split(',').first.trim();
    _mapController.move(ll.LatLng(place.lat, place.lng), 16);
    setState(() {
      _center = ll.LatLng(place.lat, place.lng);
      _confirmed = false;
      _searchResults = [];
      _searchController.clear();
    });
  }

  Future<void> _confirmLocation() async {
    setState(() => _confirming = true);
    final repo = ref.read(addListingRepositoryProvider);
    final notifier = ref.read(wizardDraftProvider.notifier);
    try {
      final neighborhood = await repo.reverseGeocode(
        lat: _center.latitude,
        lng: _center.longitude,
      );
      notifier.setLocation(
        lat: _center.latitude,
        lng: _center.longitude,
        neighborhoodId: neighborhood?.id,
        neighborhoodNameAr: neighborhood?.nameAr,
      );
      final placeName = _searchedPlaceName;
      if (_landmarkController.text.trim().isEmpty && placeName != null) {
        _landmarkController.text = placeName;
        notifier.setLandmark(placeName);
      }
      if (!mounted) return;
      setState(() {
        _confirmed = true;
        _confirming = false;
      });
    } on ApiException {
      // Reverse geocoding is a convenience (fills the neighborhood field); its failure
      // shouldn't block confirming the point itself — the dropdown is still editable.
      notifier.setLocation(lat: _center.latitude, lng: _center.longitude);
      if (!mounted) return;
      setState(() {
        _confirmed = true;
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = ref.watch(wizardDraftProvider);
    final notifier = ref.read(wizardDraftProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 15,
                  onMapEvent: _onMapEvent,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'sy.albab.mobile',
                  ),
                ],
              ),
              IgnorePointer(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 34),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                      child: const MapPin(
                        propertyType: PropertyType.house,
                        selected: true,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                right: AppSpacing.md,
                child: Column(
                  children: [
                    Material(
                      elevation: 2,
                      borderRadius: AppRadius.cardRadius,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          hintText: l10n.searchPlaceholder,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.cardRadius,
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: _search,
                      ),
                    ),
                    if (_searchResults.isNotEmpty)
                      Material(
                        elevation: 2,
                        borderRadius: AppRadius.cardRadius,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.place_outlined),
                              title: Text(result.displayName, maxLines: 2),
                              onTap: () => _selectPlace(result),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (!_confirmed)
                Positioned(
                  bottom: AppSpacing.md,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Text(
                    l10n.wizardDragMapHint,
                    textAlign: TextAlign.center,
                    style: AppTypography.label.copyWith(
                      backgroundColor: AppColors.surface.withValues(alpha: 0.9),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: !_confirmed
              ? PrimaryButton(
                  label: l10n.wizardConfirmLocation,
                  isLoading: _confirming,
                  onPressed: _confirmLocation,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WizardNeighborhoodField(
                      async: ref.watch(_wizardNeighborhoodsProvider),
                      value: draft.neighborhoodId,
                      onChanged: (id) {
                        final neighborhoods =
                            ref.read(_wizardNeighborhoodsProvider).value ??
                            const [];
                        final match = neighborhoods.where((n) => n.id == id);
                        notifier.setLocation(
                          lat: draft.lat!,
                          lng: draft.lng!,
                          neighborhoodId: id,
                          neighborhoodNameAr: match.isEmpty
                              ? null
                              : match.first.nameAr,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _landmarkController,
                      label: l10n.wizardLandmarkLabel,
                      hint: l10n.wizardLandmarkHint,
                      onChanged: notifier.setLandmark,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
