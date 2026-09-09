import 'package:albab_core/albab_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single source of truth for what's currently filtering the map + list (brief P6 "Not now"
/// / P7 item 1). P6 only ever sets [bbox] (from the map camera) and [query] (the search bar);
/// every other field is a placeholder P7's filter sheet populates — P6's map and list already
/// read all of them so P7 can drop the sheet in without touching this screen again.
///
/// Hand-written (not `@freezed`) on purpose: `apps/mobile` has no `build_runner`/codegen step
/// today (unlike `albab_core`), and adding one just for this one class would be exactly the
/// kind of premature tooling brief §10 warns against. `copyWith` is small enough to hand-roll.
class MapFilters {
  const MapFilters({
    this.purpose,
    this.propertyType,
    this.neighborhoodId,
    this.priceMin,
    this.priceMax,
    this.areaMin,
    this.areaMax,
    this.bedrooms,
    this.query,
    this.bbox,
  });

  final ListingPurpose? purpose;
  final PropertyType? propertyType;
  final int? neighborhoodId;
  final num? priceMin;
  final num? priceMax;
  final num? areaMin;
  final num? areaMax;

  /// Wire value already: `null` (الكل), `"1"`..`"4"` (exact) or `"5+"` (at least) per brief §8.
  final String? bedrooms;
  final String? query;

  /// `minLng,minLat,maxLng,maxLat`, set from the map's current viewport.
  final String? bbox;

  bool get isDefault =>
      purpose == null &&
      propertyType == null &&
      neighborhoodId == null &&
      priceMin == null &&
      priceMax == null &&
      areaMin == null &&
      areaMax == null &&
      bedrooms == null &&
      (query == null || query!.isEmpty);

  MapFilters copyWith({
    ListingPurpose? Function()? purpose,
    PropertyType? Function()? propertyType,
    int? Function()? neighborhoodId,
    num? Function()? priceMin,
    num? Function()? priceMax,
    num? Function()? areaMin,
    num? Function()? areaMax,
    String? Function()? bedrooms,
    String? Function()? query,
    String? Function()? bbox,
  }) {
    return MapFilters(
      purpose: purpose == null ? this.purpose : purpose(),
      propertyType: propertyType == null ? this.propertyType : propertyType(),
      neighborhoodId: neighborhoodId == null ? this.neighborhoodId : neighborhoodId(),
      priceMin: priceMin == null ? this.priceMin : priceMin(),
      priceMax: priceMax == null ? this.priceMax : priceMax(),
      areaMin: areaMin == null ? this.areaMin : areaMin(),
      areaMax: areaMax == null ? this.areaMax : areaMax(),
      bedrooms: bedrooms == null ? this.bedrooms : bedrooms(),
      query: query == null ? this.query : query(),
      bbox: bbox == null ? this.bbox : bbox(),
    );
  }

  /// Every non-null field as a `GET /listings/`-or-`/listings/map/` query param (brief §8).
  Map<String, dynamic> toQueryParams() {
    return {
      if (purpose != null) 'purpose': purpose!.wireValue,
      if (propertyType != null) 'property_type': propertyType!.wireValue,
      if (neighborhoodId != null) 'neighborhood': neighborhoodId,
      if (priceMin != null) 'min_price': priceMin,
      if (priceMax != null) 'max_price': priceMax,
      if (areaMin != null) 'min_area': areaMin,
      if (areaMax != null) 'max_area': areaMax,
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (query != null && query!.isNotEmpty) 'q': query,
      if (bbox != null) 'bbox': bbox,
    };
  }
}

class MapFiltersNotifier extends Notifier<MapFilters> {
  @override
  MapFilters build() => const MapFilters();

  void setBbox(String bbox) => state = state.copyWith(bbox: () => bbox);

  void setQuery(String? query) => state = state.copyWith(query: () => query);

  void reset() => state = const MapFilters();

  /// Commits a filter-sheet draft (brief P7) wholesale — the sheet builds its own local
  /// [MapFilters] (seeded from this provider's current state, so `bbox`/`query` carry
  /// through untouched) and only replaces the shared state once "عرض النتائج" is tapped.
  void apply(MapFilters filters) => state = filters;
}

final mapFiltersProvider = NotifierProvider<MapFiltersNotifier, MapFilters>(
  MapFiltersNotifier.new,
);
