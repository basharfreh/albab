import 'package:albab_core/albab_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UC-18 — `GET /favorites/`, plain (unpaginated, docs/API.md) list of the requester's
/// favorited listings as `ListingCardSerializer`. Add/remove already live on
/// `ListingDetailRepository` (P8) — favorited/unfavorited from either the detail screen or
/// this grid should behave identically, so this doesn't duplicate those two calls.
class FavoritesRepository {
  FavoritesRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<List<Listing>> fetchFavorites() async {
    try {
      final response = await _api.dio.get<List<dynamic>>('/favorites/');
      return response.data!.map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(ref),
);
