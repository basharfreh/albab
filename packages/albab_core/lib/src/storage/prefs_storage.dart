import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive local prefs — locale choice and the onboarding-seen flag. Tokens never
/// belong here; see [TokenStorage] for those.
class PrefsStorage {
  PrefsStorage({SharedPreferencesAsync? prefs}) : _prefs = prefs ?? SharedPreferencesAsync();

  static const _localeKey = 'albab_locale';
  static const _onboardingSeenKey = 'albab_onboarding_seen';
  static const _recentSearchesKey = 'albab_recent_searches';
  static const _wizardDraftIdKey = 'albab_wizard_draft_id';
  static const _wizardStepKey = 'albab_wizard_step';
  static const _pushEnabledKey = 'albab_push_enabled';

  /// Brief P7 item 5: "recent searches stored locally, max 8".
  static const maxRecentSearches = 8;

  final SharedPreferencesAsync _prefs;

  Future<String?> readLocaleCode() => _prefs.getString(_localeKey);

  Future<void> saveLocaleCode(String code) => _prefs.setString(_localeKey, code);

  Future<bool> readOnboardingSeen() async => await _prefs.getBool(_onboardingSeenKey) ?? false;

  Future<void> saveOnboardingSeen(bool seen) => _prefs.setBool(_onboardingSeenKey, seen);

  /// Most-recent-first, deduplicated, capped at [maxRecentSearches].
  Future<List<String>> readRecentSearches() async =>
      await _prefs.getStringList(_recentSearchesKey) ?? const [];

  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final current = await readRecentSearches();
    final updated = [
      trimmed,
      ...current.where((existing) => existing != trimmed),
    ].take(maxRecentSearches).toList();
    await _prefs.setStringList(_recentSearchesKey, updated);
  }

  Future<void> clearRecentSearches() => _prefs.remove(_recentSearchesKey);

  /// Brief P9 item 6: "killing the app mid-wizard resumes from the same step." The wizard
  /// already persists every field to the real `draft` listing server-side (PATCH after each
  /// step) — the only thing local storage needs to remember is *which* draft and *which*
  /// step, so a relaunch can fetch the rest back from `GET /listings/{id}/`.
  Future<int?> readWizardDraftId() => _prefs.getInt(_wizardDraftIdKey);

  Future<int> readWizardStep() async => await _prefs.getInt(_wizardStepKey) ?? 0;

  Future<void> saveWizardProgress({required int draftId, required int step}) async {
    await _prefs.setInt(_wizardDraftIdKey, draftId);
    await _prefs.setInt(_wizardStepKey, step);
  }

  Future<void> clearWizardProgress() async {
    await _prefs.remove(_wizardDraftIdKey);
    await _prefs.remove(_wizardStepKey);
  }

  /// Settings screen's "الإشعارات الفورية" toggle (brief P10 item 7). Local-only — push
  /// delivery itself is still the no-op backend until P12 wires up FCM (UC-42), so this
  /// records the user's preference for whenever that's in place, rather than calling a
  /// notification-preferences endpoint that doesn't exist (brief §8's fixed list has none).
  Future<bool> readPushEnabled() async => await _prefs.getBool(_pushEnabledKey) ?? true;

  Future<void> savePushEnabled(bool enabled) => _prefs.setBool(_pushEnabledKey, enabled);
}
