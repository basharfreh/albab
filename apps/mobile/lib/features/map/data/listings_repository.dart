import 'package:albab_core/albab_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../discovery/data/map_filters.dart';

/// `GET /listings/map/`'s response shape: markers (capped at 500) plus a `truncated` flag
/// (docs/API.md) — not the standard `Paginated<T>` envelope, so it isn't one of
/// `albab_core`'s generated models. Hand-written, matching the pattern `AuthRepository`
/// already set for endpoint response shapes that live outside the shared package.
class MapMarkersResult {
  const MapMarkersResult({required this.results, required this.truncated});

  factory MapMarkersResult.fromJson(Map<String, dynamic> json) {
    return MapMarkersResult(
      results: (json['results'] as List)
          .map((e) => ListingMapMarker.fromJson(e as Map<String, dynamic>))
          .toList(),
      truncated: json['truncated'] as bool? ?? false,
    );
  }

  final List<ListingMapMarker> results;
  final bool truncated;
}

/// Kinds `POST /listings/{id}/events/` accepts (docs/API.md) — `view` fires once per detail
/// screen open (brief P6 item 7), `call`/`whatsapp`/`share` belong to P8's contact bar.
enum ListingEventKind {
  view,
  call,
  whatsapp,
  share;

  String get wireValue => name;
}

/// `GET /listings/map/`, `GET /listings/` and `GET /listings/{id}/` — everything UC-10/11/14
/// needs from the catalog API. Calls `dio` directly per the pattern `AuthRepository` set in
/// P5 (endpoint methods live in app-level repositories, not the shared `ApiClient`).
class ListingsRepository {
  ListingsRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<MapMarkersResult> fetchMapMarkers(MapFilters filters) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/listings/map/',
        queryParameters: filters.toQueryParams(),
      );
      return MapMarkersResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<Paginated<Listing>> fetchListings(MapFilters filters, {int page = 1}) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/listings/',
        queryParameters: {...filters.toQueryParams(), 'page': page},
      );
      return Paginated<Listing>.fromJson(
        response.data!,
        (json) => Listing.fromJson(json! as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<Listing> fetchListingDetail(int id) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('/listings/$id/');
      return Listing.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// `GET /neighborhoods/` — active neighborhoods, unpaginated (docs/API.md: "small
  /// reference list"), for the filter screen's الحي dropdown.
  Future<List<Neighborhood>> fetchNeighborhoods() async {
    try {
      final response = await _api.dio.get<List<dynamic>>('/neighborhoods/');
      return response.data!
          .map((e) => Neighborhood.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// The filter screen's live count (brief P7 item 3, docs/API.md): `page_size=1`, read
  /// `count` from the standard paginated envelope — no separate count endpoint.
  Future<int> fetchResultsCount(MapFilters filters) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/listings/',
        queryParameters: {...filters.toQueryParams(), 'page_size': 1},
      );
      return response.data!['count'] as int;
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// Anonymous-allowed, throttled server-side (docs/API.md) — errors are swallowed rather
  /// than surfaced, since a dropped analytics ping should never block or alarm the user.
  Future<void> postEvent(int listingId, ListingEventKind kind) async {
    try {
      await _api.dio.post<void>(
        '/listings/$listingId/events/',
        data: {'kind': kind.wireValue},
      );
    } on DioException {
      // best-effort
    }
  }
}

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) => ListingsRepository(ref));
