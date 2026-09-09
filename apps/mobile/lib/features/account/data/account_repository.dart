import 'package:albab_core/albab_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The two row counts the account screen shows next to "عقاراتي"/"المفضلة" (brief P10 item
/// 1) — neither has a dedicated count endpoint, so this reads `count` off a `page_size=1`
/// request the same way the filter screen's live count does (brief §8), and the length of
/// `/favorites/`'s plain (unpaginated, per docs/API.md) list.
class AccountCounts {
  const AccountCounts({required this.myListings, required this.favorites});

  final int myListings;
  final int favorites;
}

/// Everything the account tab and its "عقاراتي"/"المفضلة" row counts need beyond what
/// [AuthRepository] (profile) and the feature-owned repositories (my listings, favorites
/// lists themselves) already cover. A separate small repository, matching the pattern P7's
/// `GeoRepository`/P8's `ListingDetailRepository` set: feature-owned calls live next to the
/// feature.
class AccountRepository {
  AccountRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<AccountCounts> fetchCounts() async {
    try {
      final myListingsResponse = await _api.dio.get<Map<String, dynamic>>(
        '/me/listings/',
        queryParameters: const {'page_size': 1},
      );
      final favoritesResponse = await _api.dio.get<List<dynamic>>('/favorites/');
      final myListings = myListingsResponse.data!['count'] as int;
      final favorites = favoritesResponse.data!.length;
      return AccountCounts(myListings: myListings, favorites: favorites);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) => AccountRepository(ref));
