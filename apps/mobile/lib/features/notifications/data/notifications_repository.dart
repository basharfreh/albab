import 'package:albab_core/albab_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UC-41 — `GET /notifications/`, `POST /notifications/read-all/`, and the P10-added
/// `POST /notifications/{id}/read/` (docs/API.md — see PROGRESS.md for why the single-item
/// action needed adding).
class NotificationsRepository {
  NotificationsRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/notifications/',
        queryParameters: const {'page_size': 50},
      );
      final paginated = Paginated<AppNotification>.fromJson(
        response.data!,
        (json) => AppNotification.fromJson(json! as Map<String, dynamic>),
      );
      return paginated.results;
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<void> markRead(int notificationId) async {
    try {
      await _api.dio.post<void>('/notifications/$notificationId/read/');
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.dio.post<void>('/notifications/read-all/');
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref),
);
