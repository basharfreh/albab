import '../../l10n/app_localizations.dart';

/// Formats a past [DateTime] as `منذ 5 ساعات` / `5 hours ago`. Takes the resolved
/// [AppLocalizations] rather than a `BuildContext` directly, so it stays a plain,
/// easily-testable function. [now] is injectable for tests; defaults to [DateTime.now].
abstract final class RelativeTime {
  static String format(AppLocalizations l10n, DateTime dateTime, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(dateTime);

    if (diff.inMinutes < 1) return l10n.relativeTimeJustNow;
    if (diff.inMinutes < 60) return l10n.relativeTimeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.relativeTimeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.relativeTimeDaysAgo(diff.inDays);
    if (diff.inDays < 30) return l10n.relativeTimeWeeksAgo((diff.inDays / 7).floor());
    if (diff.inDays < 365) return l10n.relativeTimeMonthsAgo((diff.inDays / 30).floor());
    return l10n.relativeTimeYearsAgo((diff.inDays / 365).floor());
  }
}
