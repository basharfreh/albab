import 'package:albab_core/albab_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final apiClient = ApiClient(baseUrl: 'http://example.test', tokenStorage: TokenStorage());

  DioException unauthorized({Map<String, dynamic>? data}) {
    final requestOptions = RequestOptions(path: '/auth/login/');
    return DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: requestOptions, statusCode: 401, data: data),
    );
  }

  test('a 401 with a server {"detail": ...} keeps that message (wrong password, blocked account)', () {
    final exception = apiClient.mapError(unauthorized(data: {'detail': 'تم حظر هذا الحساب.'}));

    expect(exception.kind, ApiErrorKind.unauthorized);
    expect(exception.message, 'تم حظر هذا الحساب.');
  });

  test('a 401 with no body (an expired token) falls back to the generic message', () {
    final exception = apiClient.mapError(unauthorized());

    expect(exception.kind, ApiErrorKind.unauthorized);
    expect(exception.message, isNull);
  });
}
