import '../../l10n/app_localizations.dart';

/// Broad cause of an [ApiException], used to pick a localized fallback message when the
/// server didn't send one (a raw network failure has no DRF `{"detail": ...}` body to show).
enum ApiErrorKind { network, timeout, unauthorized, server, unknown }

/// What an [ApiClient] call throws on any non-2xx response or transport failure. [message]
/// is the server's own `{"detail": "..."}` text when there was one; [fieldErrors] mirrors
/// DRF's `{"field": ["..."]}` validation shape. Call [localizedMessage] to get something
/// displayable even when the server gave nothing (timeouts, connection errors).
class ApiException implements Exception {
  const ApiException({
    required this.kind,
    this.message,
    this.fieldErrors = const {},
    this.statusCode,
  });

  final ApiErrorKind kind;
  final String? message;
  final Map<String, List<String>> fieldErrors;
  final int? statusCode;

  String localizedMessage(AppLocalizations l10n) {
    final serverMessage = message;
    if (serverMessage != null && serverMessage.isNotEmpty) return serverMessage;
    return switch (kind) {
      ApiErrorKind.network => l10n.errorNetwork,
      ApiErrorKind.timeout => l10n.errorTimeout,
      ApiErrorKind.unauthorized => l10n.errorUnauthorized,
      ApiErrorKind.server || ApiErrorKind.unknown => l10n.errorUnknown,
    };
  }

  @override
  String toString() => 'ApiException(kind: $kind, statusCode: $statusCode, message: $message)';
}
