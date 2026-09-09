import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/user.dart';
import '../storage/prefs_storage.dart';
import '../storage/token_storage.dart';
import 'auth_state.dart';

const _defaultApiBaseUrl = 'http://localhost:8000/api/v1';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final prefsStorageProvider = Provider<PrefsStorage>((ref) => PrefsStorage());

/// Base URL from `--dart-define=API_BASE_URL` (brief §7), falling back to a local dev
/// backend so `flutter run` works with no flags out of the box.
final apiClientProvider = Provider<ApiClient>((ref) {
  const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: _defaultApiBaseUrl);
  return ApiClient(baseUrl: baseUrl, tokenStorage: ref.watch(tokenStorageProvider));
});

class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.unknown();

  void setGuest() => state = const AuthState.guest();

  void setAuthenticated(User user) => state = AuthState.authenticated(user);

  /// Clears stored tokens and drops back to guest — P5's account screen "تسجيل الخروج"
  /// wires straight into this.
  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AuthState.guest();
  }
}

final authStateProvider = NotifierProvider<AuthStateNotifier, AuthState>(AuthStateNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _restore();
    return const Locale('ar'); // ar first (brief §9) until the saved preference loads
  }

  Future<void> _restore() async {
    final saved = await ref.read(prefsStorageProvider).readLocaleCode();
    if (saved != null) state = Locale(saved);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref.read(prefsStorageProvider).saveLocaleCode(locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
