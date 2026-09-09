/// Formats an E.164 Syrian phone number (`+963987654321`) for display as
/// `+963 987 654 321` — grouped in 3s, always LTR inside Arabic text (brief §9).
abstract final class PhoneFormat {
  static String display(String e164) {
    final digits = e164.startsWith('+') ? e164.substring(1) : e164;
    if (!digits.startsWith('963') || digits.length != 12) {
      return e164; // not a recognized Syrian E.164 number — show as-is rather than mangle it
    }

    final countryCode = digits.substring(0, 3);
    final rest = digits.substring(3);
    final groups = [rest.substring(0, 3), rest.substring(3, 6), rest.substring(6, 9)];
    return '+$countryCode ${groups.join(' ')}';
  }
}
