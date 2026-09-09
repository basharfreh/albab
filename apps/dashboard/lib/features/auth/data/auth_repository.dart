import 'package:albab_core/albab_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session handling for the dashboard (brief P11 item 2: "login route restricted to
/// `role=admin`; any other role gets a clear rejection, not a blank screen"). A dashboard-
/// local copy of `apps/mobile`'s `AuthRepository` rather than a shared one — P4 scoped
/// repositories as per-app ("Not now: Repositories for specific features"), and this one's
/// surface is deliberately smaller (no register/OTP/profile-edit, none of which the
/// dashboard has a screen for) plus the admin-only check mobile has no reason to carry.
class AuthRepository {
  AuthRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);
  TokenStorage get _tokens => _ref.read(tokenStorageProvider);

  /// Called once at app boot. A stored token for a non-admin user is treated the same as no
  /// session at all — `restoreSession` alone can't show the rejection message (no screen is
  /// on-screen yet to show it on), so it silently drops back to `guest` and the router sends
  /// the user to `/login`, which resolves to the guest sign-in form either way.
  Future<void> restoreSession() async {
    final access = await _tokens.readAccessToken();
    if (access == null) {
      _ref.read(authStateProvider.notifier).setGuest();
      return;
    }
    try {
      final user = await fetchMe();
      if (user.role == UserRole.admin) {
        _ref.read(authStateProvider.notifier).setAuthenticated(user);
      } else {
        await _tokens.clear();
        _ref.read(authStateProvider.notifier).setGuest();
      }
    } on ApiException {
      await _tokens.clear();
      _ref.read(authStateProvider.notifier).setGuest();
    }
  }

  Future<User> fetchMe() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('/auth/me/');
      return User.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// `POST /auth/login/` then `GET /auth/me/`. Throws [DashboardAccessDeniedException] for a
  /// working login on a non-admin account — tokens are cleared immediately rather than left
  /// stored for an account that will never be let past `/login` here.
  Future<void> login({required String phone, required String password}) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/auth/login/',
        data: {'phone': phone, 'password': password},
      );
      final access = response.data!['access'] as String;
      final refresh = response.data!['refresh'] as String;
      await _tokens.saveTokens(access: access, refresh: refresh);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
    final user = await fetchMe();
    if (user.role != UserRole.admin) {
      await _tokens.clear();
      throw const DashboardAccessDeniedException();
    }
    _ref.read(authStateProvider.notifier).setAuthenticated(user);
  }

  Future<void> logout() => _ref.read(authStateProvider.notifier).logout();
}

/// A real login that isn't for an admin account — distinct from [ApiException] so the login
/// screen can show brief P11's "clear rejection" copy instead of a generic server error.
class DashboardAccessDeniedException implements Exception {
  const DashboardAccessDeniedException();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref));
