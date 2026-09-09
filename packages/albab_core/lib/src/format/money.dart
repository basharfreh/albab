import 'package:intl/intl.dart';

/// Formats a decimal-string price (the API's wire format, e.g. `"85000.00"` — see brief §8:
/// "Money as a decimal string, never a float") as `$85,000`. Locale-fixed to `en_US` grouping
/// regardless of the active app locale — prices stay LTR inside Arabic text (brief §9).
abstract final class Money {
  static final _format = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 0);

  static String format(String decimalString) {
    final value = num.tryParse(decimalString) ?? 0;
    return _format.format(value);
  }
}
