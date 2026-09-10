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
  /// `AdminListingQueueView` on the backend. `?owner=` (also P11) is what the المستخدمين
  /// row drawer uses to fetch one user's listings.
  Future<List<Listing>> fetchAdminListings({
    String? status,
    String ordering = '-created_at',
    int pageSize = 20,
    int? ownerId,
  }) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/admin/listings/',
        queryParameters: {
          'status': ?status,
          'ordering': ordering,
          'page_size': pageSize,
          'owner': ?ownerId,
        },
      );
      final results = response.data!['results'] as List<dynamic>;
      return results.map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// UC-55: `?role=` filter, `?q=` search on name/phone.
  Future<List<User>> fetchUsers({UserRole? role, String? q}) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/admin/users/',
        queryParameters: {'role': ?role?.wireValue, 'q': ?q, 'page_size': 50},
      );
      final results = response.data!['results'] as List<dynamic>;
      return results.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// `reason` is only persisted server-side while the block is in effect (docs/API.md) —
  /// pass `null`/empty to unblock.
  Future<User> setUserBlocked(int id, {required bool blocked, String? reason}) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/admin/users/$id/block/',
        data: {'blocked': blocked, 'reason': ?reason},
      );
      return User.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<User> setUserRole(int id, UserRole role) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/admin/users/$id/role/',
        data: {'role': role.wireValue},
      );
      return User.fromJson(response.data!);
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

  /// UC-58: `?status=` filter (`open`/`closed`).
  Future<List<AdminReport>> fetchReports({String? status}) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/admin/reports/',
        queryParameters: {'status': ?status, 'page_size': 50},
      );
      final results = response.data!['results'] as List<dynamic>;
      return results.map((e) => AdminReport.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// The backend only has one terminal action on a report (`close`) — no separate
  /// resolve/dismiss distinction (see docs/PROGRESS.md's P3 decisions), so this is the one
  /// action التقارير's "close report" button calls either way.
  Future<void> closeReport(int id) async {
    try {
      await _api.dio.post<void>('/admin/reports/$id/close/');
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// UC-59: unlike the public `/neighborhoods/` (active-only), this lists every row.
  Future<List<AdminNeighborhood>> fetchAdminNeighborhoods() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/admin/neighborhoods/',
        queryParameters: {'page_size': 50},
      );
      final results = response.data!['results'] as List<dynamic>;
      return results
          .map((e) => AdminNeighborhood.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<AdminNeighborhood> createNeighborhood(AdminNeighborhood neighborhood) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/admin/neighborhoods/',
        data: neighborhood.toJson(),
      );
      return AdminNeighborhood.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<AdminNeighborhood> updateNeighborhood(AdminNeighborhood neighborhood) async {
    try {
      final response = await _api.dio.patch<Map<String, dynamic>>(
        '/admin/neighborhoods/${neighborhood.id}/',
        data: neighborhood.toJson(),
      );
      return AdminNeighborhood.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// The backend rejects this with a 400 (not a 500) when listings still reference the
  /// neighborhood (`on_delete=PROTECT`) — deactivating is the intended way to retire one.
  Future<void> deleteNeighborhood(int id) async {
    try {
      await _api.dio.delete<void>('/admin/neighborhoods/$id/');
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<QuotaSettings> fetchQuotaSettings() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('/admin/settings/quotas/');
      return QuotaSettings.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<QuotaSettings> updateQuotaSettings(QuotaSettings quotas) async {
    try {
      final response = await _api.dio.patch<Map<String, dynamic>>(
        '/admin/settings/quotas/',
        data: {'seeker': quotas.seeker, 'owner': quotas.owner, 'agency': quotas.agency},
      );
      return QuotaSettings.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<List<AdminStaticPage>> fetchStaticPages() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/admin/settings/pages/',
        queryParameters: {'page_size': 50},
      );
      final results = response.data!['results'] as List<dynamic>;
      return results.map((e) => AdminStaticPage.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<AdminStaticPage> createStaticPage(AdminStaticPage page) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/admin/settings/pages/',
        data: page.toJson(),
      );
      return AdminStaticPage.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<AdminStaticPage> updateStaticPage(AdminStaticPage page) async {
    try {
      final response = await _api.dio.patch<Map<String, dynamic>>(
        '/admin/settings/pages/${page.id}/',
        data: page.toJson(),
      );
      return AdminStaticPage.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<void> deleteStaticPage(int id) async {
    try {
      await _api.dio.delete<void>('/admin/settings/pages/$id/');
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminRepository(ref));
