import 'package:albab_core/albab_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The three OTP purposes `/auth/otp/*` accepts (brief §1/docs/API.md). Only `register` is
/// wired to a screen in this phase — the verify screen after sign-up (UC-04). `login`/
/// `password_reset` exist on the backend already but have no P5 "Do"-listed screen yet.
enum OtpPurpose {
  register,
  login,
  passwordReset;

  String get wireValue => switch (this) {
    OtpPurpose.register => 'register',
    OtpPurpose.login => 'login',
    OtpPurpose.passwordReset => 'password_reset',
  };
}

/// Everything UC-01…UC-07 needs from `/auth/*`. Calls `dio` directly (rather than adding
/// endpoint methods to the shared [ApiClient], which brief §7/P4 scoped to the generic
/// wrapper only) and drives [authStateProvider] on success — this is the piece P4's own
/// "Next agent" note flagged as still missing: nothing in `albab_core` called `/auth/*` yet.
class AuthRepository {
  AuthRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);
  TokenStorage get _tokens => _ref.read(tokenStorageProvider);

  /// Called once at app boot (from the splash route). Resolves [authStateProvider] out of
  /// `unknown` into `guest` (no stored token, or a stored token that no longer works) or
  /// `authenticated` (a working stored token) — this is what makes "login persists across
  /// restart" true.
  Future<void> restoreSession() async {
    final access = await _tokens.readAccessToken();
    if (access == null) {
      _ref.read(authStateProvider.notifier).setGuest();
      return;
    }
    try {
      final user = await fetchMe();
      _ref.read(authStateProvider.notifier).setAuthenticated(user);
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

  /// `POST /auth/register/` — returns the created user, no tokens (P1 decision: register
  /// and login are two separate steps). Does not touch [authStateProvider].
  Future<User> register({
    required String phone,
    required String name,
    required String password,
    required UserRole role,
    String? agencyName,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/auth/register/',
        data: {
          'phone': phone,
          'name': name,
          'password': password,
          'role': role.wireValue,
          if (agencyName != null && agencyName.trim().isNotEmpty) 'agency_name': agencyName,
        },
      );
      return User.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// `POST /auth/login/` then `GET /auth/me/`, saving tokens and setting `authenticated` on
  /// success. Accepts any Syrian phone format — the backend normalizes before authenticating.
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
    _ref.read(authStateProvider.notifier).setAuthenticated(user);
  }

  /// `POST /auth/otp/request/`. Returns `debug_code` when the server includes one (`DEBUG`
  /// only) so a dev build can show it without a real SMS gateway.
  Future<String?> requestOtp({required String phone, required OtpPurpose purpose}) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/auth/otp/request/',
        data: {'phone': phone, 'purpose': purpose.wireValue},
      );
      return response.data?['debug_code'] as String?;
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// `POST /auth/otp/verify/`. Throws [ApiException] on a wrong/expired code.
  Future<void> verifyOtp({
    required String phone,
    required OtpPurpose purpose,
    required String code,
  }) async {
    try {
      await _api.dio.post<Map<String, dynamic>>(
        '/auth/otp/verify/',
        data: {'phone': phone, 'purpose': purpose.wireValue, 'code': code},
      );
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<void> logout() => _ref.read(authStateProvider.notifier).logout();

  /// `PATCH /auth/me/` — brief P10 item 7's "edit profile (name, avatar, WhatsApp number)".
  /// Sent as multipart whenever an avatar is attached (mirrors
  /// `AddListingRepository.uploadImage`'s `MultipartFile.fromFile`), plain JSON otherwise —
  /// DRF's `MultiPartParser`/`JSONParser` on `MeView` accept either. Updates
  /// [authStateProvider] with the server's own response so every screen reading the
  /// authenticated user (account header, nav badges) reflects the change immediately.
  Future<User> updateProfile({
    String? name,
    String? whatsappPhone,
    String? avatarPath,
  }) async {
    try {
      final data = avatarPath == null
          ? {'name': ?name, 'whatsapp_phone': ?whatsappPhone}
          : FormData.fromMap({
              'name': ?name,
              'whatsapp_phone': ?whatsappPhone,
              'avatar': await MultipartFile.fromFile(
                avatarPath,
                filename: avatarPath.split('/').last,
              ),
            });
      final response = await _api.dio.patch<Map<String, dynamic>>('/auth/me/', data: data);
      final user = User.fromJson(response.data!);
      _ref.read(authStateProvider.notifier).setAuthenticated(user);
      return user;
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref));
