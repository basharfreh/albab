import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Isolated coverage of the widget itself — see `map_home_screen_test.dart` for the
/// full end-to-end proof that a real paginated screen wires `hasError`/`onRetry` correctly.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('shows a spinner, not a retry row, while not in an error state', (tester) async {
    await tester.pumpWidget(wrap(const PaginationFooter(hasError: false)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsNothing);
  });

  testWidgets(
    'shows a tappable retry row instead of a spinner once the last attempt failed '
    '(brief P12 item 5: "no infinite spinners")',
    (tester) async {
      var retried = false;
      await tester.pumpWidget(
        wrap(PaginationFooter(hasError: true, onRetry: () => retried = true)),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('تعذر تحميل المزيد، إعادة المحاولة'), findsOneWidget);

      await tester.tap(find.text('تعذر تحميل المزيد، إعادة المحاولة'));
      expect(retried, isTrue);
    },
  );
}
