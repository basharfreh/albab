import 'package:albab_core/albab_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_models.dart';

/// Everything the dashboard's home + listings screens need from `/admin/*` (docs/API.md,
/// P3). Mirrors `AuthRepository`'s shape (brief P4 scoped `ApiClient` to the generic
/// wrapper only, so endpoint methods live in a repository, not on the client itself).
class AdminRepository {
  AdminRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<AdminKpis> fetchKpis() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('/admin/kpis/');
      return AdminKpis.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<List<VisitsPoint>> fetchVisits({int days = 30}) async {
    try {
      final response = await _api.dio.get<List<dynamic>>(
        '/admin/analytics/visits/',
        queryParameters: {'days': days},
      );
      return response.data!
          .map((e) => VisitsPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<List<ByTypeSlice>> fetchByType() async {
    try {
      final response = await _api.dio.get<List<dynamic>>('/admin/analytics/by-type/');
      return response.data!.map((e) => ByTypeSlice.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// `?ordering=` is the P11 addition (docs/API.md) this same call uses for both "latest
  /// added" (`-created_at`, the default) and "most viewed" (`-views_count`) — see
  /// `AdminListingQueueView` on the backend.
  Future<List<Listing>> fetchAdminListings({
    String? status,
    String ordering = '-created_at',
    int pageSize = 20,
  }) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/admin/listings/',
        queryParameters: {'status': ?status, 'ordering': ordering, 'page_size': pageSize},
      );
      final results = response.data!['results'] as List<dynamic>;
      return results.map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<Listing> approveListing(int id) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/admin/listings/$id/approve/',
      );
      return Listing.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<Listing> rejectListing(int id, String reason) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/admin/listings/$id/reject/',
        data: {'reason': reason},
      );
      return Listing.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminRepository(ref));
