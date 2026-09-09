import 'package:albab_core/albab_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Everything UC-15…UC-20 needs beyond what [ListingsRepository] already covers
/// (`fetchListingDetail`, `postEvent`) — favorites, reporting, and the "similar
/// properties" strip. A separate small repository, matching the pattern P7's
/// `GeoRepository` set: feature-owned calls live next to the feature, not bolted onto the
/// map/list repository whose own docstring scopes it to UC-10/11/14.
class ListingDetailRepository {
  ListingDetailRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<void> addFavorite(int listingId) async {
    try {
      await _api.dio.post<void>('/favorites/', data: {'listing': listingId});
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<void> removeFavorite(int listingId) async {
    try {
      await _api.dio.delete<void>('/favorites/$listingId/');
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// UC-20 — `reason` is one of the fixed reason keys the report sheet offers; `note` is
  /// the optional free-text field.
  Future<void> report(int listingId, {required String reason, String? note}) async {
    try {
      await _api.dio.post<void>(
        '/listings/$listingId/report/',
        data: {'reason': reason, if (note != null && note.isNotEmpty) 'note': note},
      );
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// Brief P8 item 7: "same neighborhood or type, price within ±30%, excluding the current
  /// listing." `GET /listings/` has no "exclude id" or "neighborhood name" filter (only
  /// `neighborhood` by id, which [Listing] — built from `ListingDetailSerializer` — doesn't
  /// carry; only `neighborhoodName` does), so this issues two requests inside the same
  /// price band — one by `property_type`, one by neighborhood name via the free-text `q`
  /// filter (which already searches `neighborhood__name_ar__icontains`, brief §8) — and
  /// merges them, deduped, excluding [listing.id] itself, capped at 10.
  Future<List<Listing>> fetchSimilar(Listing listing) async {
    final price = num.tryParse(listing.price ?? '');
    final priceParams = price == null
        ? const <String, dynamic>{}
        : {'min_price': (price * 0.7).toStringAsFixed(2), 'max_price': (price * 1.3).toStringAsFixed(2)};

    final byType = _fetch({
      'property_type': listing.propertyType.wireValue,
      ...priceParams,
      'page_size': 10,
    });
    final neighborhood = listing.neighborhoodName;
    final byNeighborhood = neighborhood == null || neighborhood.isEmpty
        ? Future.value(const <Listing>[])
        : _fetch({'q': neighborhood, ...priceParams, 'page_size': 10});

    final results = await Future.wait([byType, byNeighborhood]);
    final merged = <int, Listing>{};
    for (final page in results) {
      for (final item in page) {
        if (item.id != listing.id) merged[item.id] = item;
      }
    }
    return merged.values.take(10).toList();
  }

  Future<List<Listing>> _fetch(Map<String, dynamic> queryParameters) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/listings/',
        queryParameters: queryParameters,
      );
      final paginated = Paginated<Listing>.fromJson(
        response.data!,
        (json) => Listing.fromJson(json! as Map<String, dynamic>),
      );
      return paginated.results;
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }
}

final listingDetailRepositoryProvider = Provider<ListingDetailRepository>(
  (ref) => ListingDetailRepository(ref),
);
