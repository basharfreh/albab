import 'package:albab_core/albab_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One `GET /geo/search/?q=` result — a place, not a listing (`apps/catalog/services/geo.py`
/// proxies Nominatim's own `display_name`/`lat`/`lon`, Al-Bab-bounded and 24h-cached
/// server-side). Hand-written, matching the pattern `MapMarkersResult` set for a response
/// shape that isn't the standard `Paginated<T>` envelope.
class PlaceResult {
  const PlaceResult({required this.displayName, required this.lat, required this.lng});

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    return PlaceResult(
      displayName: json['display_name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  final String displayName;
  final double lat;
  final double lng;
}

/// `/geo/search/` — brief P7 item 5: "place results move the map camera instead of
/// filtering." Kept separate from [ListingsRepository] since it's a distinct concern (a
/// Nominatim proxy, not the catalog) even though both live in `apps/mobile`.
class GeoRepository {
  GeoRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<List<PlaceResult>> searchPlaces(String query) async {
    try {
      final response = await _api.dio.get<List<dynamic>>(
        '/geo/search/',
        queryParameters: {'q': query},
      );
      return response.data!
          .map((e) => PlaceResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }
}

final geoRepositoryProvider = Provider<GeoRepository>((ref) => GeoRepository(ref));
