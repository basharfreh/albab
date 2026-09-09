import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Thin Dio wrapper: JSON, 20s timeouts, an auth interceptor attaching the access token,
/// and a refresh interceptor that coalesces concurrent 401s onto a single token refresh
/// and retries each original request once. Base URL comes from `--dart-define=API_BASE_URL`
/// (brief §7) — read it once in `main()` and pass it in here, rather than each call site
/// reading the define itself.
class ApiClient {
  // `tokenStorage` is kept as the public param name on purpose — `this._tokenStorage` would
  // leak the private field name into the constructor's public API.
  ApiClient({required String baseUrl, required TokenStorage tokenStorage, Dio? dio})
    : _tokenStorage = tokenStorage, // ignore: prefer_initializing_formals
      dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              contentType: 'application/json',
            ),
          ) {
    this.dio.interceptors.addAll([_authInterceptor(), _refreshInterceptor()]);
  }

  final Dio dio;
  final TokenStorage _tokenStorage;

  /// Set while a refresh is in flight — concurrent 401s await this same future instead of
  /// each firing their own `/auth/refresh/` call.
  Future<void>? _refreshing;

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.readAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    );
  }

  Interceptor _refreshInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        final isRefreshCall = error.requestOptions.path.contains('/auth/refresh/');
        if (error.response?.statusCode != 401 || isRefreshCall) {
          return handler.next(error);
        }

        try {
          await _refreshTokenOnce();
        } catch (_) {
          await _tokenStorage.clear();
          return handler.next(error);
        }

        try {
          final token = await _tokenStorage.readAccessToken();
          final retryOptions = error.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $token';
          final response = await dio.fetch<dynamic>(retryOptions);
          return handler.resolve(response);
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      },
    );
  }

  Future<void> _refreshTokenOnce() {
    return _refreshing ??= _performRefresh().whenComplete(() => _refreshing = null);
  }

  Future<void> _performRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      throw StateError('No refresh token stored.');
    }
    // A bare Dio instance — going through `this.dio` would re-enter these same
    // interceptors and could recurse if the refresh call itself ever came back 401.
    final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
    final response = await refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh/',
      data: {'refresh': refreshToken},
    );
    final access = response.data?['access'] as String?;
    if (access == null) {
      throw StateError('Refresh response had no access token.');
    }
    await _tokenStorage.saveAccessToken(access);
  }

  /// Turns a caught error from any `dio` call into an [ApiException]. Call sites should
  /// wrap requests in `try { ... } on DioException catch (e) { throw apiClient.mapError(e); }`
  /// (or catch it directly in a repository layer once one exists — P4 ships no repositories).
  ApiException mapError(Object error) {
    if (error is! DioException) {
      return ApiException(kind: ApiErrorKind.unknown, message: error.toString());
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(kind: ApiErrorKind.timeout);
      case DioExceptionType.connectionError:
        return const ApiException(kind: ApiErrorKind.network);
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (statusCode == 401) {
      // Keep the server's own `detail` when it sent one (wrong credentials, a blocked
      // account) rather than always falling back to the generic "please log in" text —
      // a stale/expired token hitting this same branch has no `detail` to lose.
      final detail = data is Map ? data['detail'] : null;
      return ApiException(
        kind: ApiErrorKind.unauthorized,
        message: detail is String ? detail : null,
        statusCode: statusCode,
      );
    }

    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) {
        return ApiException(kind: ApiErrorKind.server, message: detail, statusCode: statusCode);
      }

      final fieldErrors = <String, List<String>>{};
      data.forEach((key, value) {
        if (value is List) {
          fieldErrors[key.toString()] = value.map((e) => e.toString()).toList();
        }
      });
      if (fieldErrors.isNotEmpty) {
        return ApiException(
          kind: ApiErrorKind.server,
          fieldErrors: fieldErrors,
          statusCode: statusCode,
        );
      }
    }

    return ApiException(kind: ApiErrorKind.unknown, statusCode: statusCode);
  }
}
