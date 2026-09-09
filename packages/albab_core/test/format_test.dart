import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('formats a decimal string with thousands separators, no cents', () {
      expect(Money.format('85000.00'), r'$85,000');
    });

    test('handles small and zero values', () {
      expect(Money.format('0.00'), r'$0');
      expect(Money.format('999.00'), r'$999');
    });

    test('falls back to zero on an unparseable string', () {
      expect(Money.format('not-a-number'), r'$0');
    });
  });

  group('PhoneFormat', () {
    test('groups a Syrian E.164 number in 3s', () {
      expect(PhoneFormat.display('+963987654321'), '+963 987 654 321');
    });

    test('returns non-Syrian numbers unchanged rather than mangling them', () {
      expect(PhoneFormat.display('+15551234567'), '+15551234567');
    });
  });

  group('AppLocalizations-dependent formatters', () {
    testWidgets('Area.format renders the Arabic unit suffix', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(Area.format(l10n, 120), '120 م²');
    });

    testWidgets('RelativeTime.format picks the right bucket', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final now = DateTime(2026, 1, 1, 12);
      expect(
        RelativeTime.format(l10n, now.subtract(const Duration(minutes: 30)), now: now),
        'منذ 30 دقيقة',
      );
      expect(
        RelativeTime.format(l10n, now.subtract(const Duration(hours: 5)), now: now),
        'منذ 5 ساعات',
      );
      expect(RelativeTime.format(l10n, now.subtract(const Duration(seconds: 10)), now: now), 'الآن');
    });
  });

  group('Model JSON round-trip', () {
    test('User deserializes snake_case wire fields', () {
      final user = User.fromJson({
        'id': 1,
        'name': 'أحمد',
        'role': 'owner',
        'avatar': null,
        'agency_name': '',
        'phone': '+963987654321',
        'whatsapp_phone': null,
        'is_phone_verified': true,
      });

      expect(user.id, 1);
      expect(user.role, UserRole.owner);
      expect(user.phone, '+963987654321');
      expect(user.isPhoneVerified, true);
    });

    test('Listing round-trips through toJson/fromJson', () {
      const listing = Listing(
        id: 5,
        title: 'شقة واسعة',
        price: '85000.00',
        purpose: ListingPurpose.sale,
        propertyType: PropertyType.apartment,
      );

      final roundTripped = Listing.fromJson(listing.toJson());
      expect(roundTripped, listing);
    });
  });
}
