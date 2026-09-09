import 'package:albab_core/albab_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UC-35/UC-36 — the owner's own listings (`/me/listings/`, `MyListingSerializer` per
/// docs/API.md) and the status-change/delete actions their row's overflow menu offers.
class MyListingsRepository {
  MyListingsRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  /// `status == null` is the "الكل" tab — no `?status=` filter, every status included.
  Future<Paginated<Listing>> fetchMyListings({String? status, int page = 1}) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/me/listings/',
        queryParameters: {'status': ?status, 'page': page},
      );
      return Paginated<Listing>.fromJson(
        response.data!,
        (json) => Listing.fromJson(json! as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// `POST /listings/{id}/status/` — "تعليق"/"إعادة النشر" from the row's overflow menu.
  /// `sold`/`rented`/`republish` (UC-36's fuller set) aren't part of P10's own itemized
  /// overflow-menu list (تعديل · تمييز · تعليق · حذف) — only pause ⇄ republish is wired here.
  Future<void> setStatus(int listingId, String status) async {
    try {
      await _api.dio.post<void>('/listings/$listingId/status/', data: {'status': status});
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<void> deleteListing(int listingId) async {
    try {
      await _api.dio.delete<void>('/listings/$listingId/');
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// The "مباع/مؤجر" tab spans two statuses, but `/me/listings/`'s `?status=` filter is a
  /// plain exact-match (no `in` support, unlike `ListingFilterSet`'s richer query params) —
  /// merges one page of each status instead of extending the filter for a single tab, same
  /// trade-off P8's `fetchSimilar` made for its own two-query merge. Not further paginated —
  /// a bounded, typically-small list in practice (a marketplace's sold/rented history).
  Future<List<Listing>> fetchByStatuses(List<String> statuses) async {
    final pages = await Future.wait(statuses.map((status) => fetchMyListings(status: status)));
    final merged = [for (final page in pages) ...page.results];
    merged.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return merged;
  }
}

final myListingsRepositoryProvider = Provider<MyListingsRepository>(
  (ref) => MyListingsRepository(ref),
);
