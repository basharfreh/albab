import '../../l10n/app_localizations.dart';

/// Formats an area in square meters as `120 م²` / `120 m²`. Takes the resolved
/// [AppLocalizations] (via `AppLocalizations.of(context)!`) rather than a `BuildContext`
/// directly, so it stays a plain, easily-testable function.
abstract final class Area {
  static String format(AppLocalizations l10n, num areaSqm) {
    final value = areaSqm == areaSqm.roundToDouble()
        ? areaSqm.toStringAsFixed(0)
        : areaSqm.toString();
    return l10n.areaUnit(value);
  }
}
