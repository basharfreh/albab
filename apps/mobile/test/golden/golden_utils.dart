import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the test surface to a fixed, device-independent size so goldens don't drift with
/// whatever size the host happens to default to. Call in `setUp`; `tearDown` resets it.
void pinSurfaceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
}

/// Wraps [child] in the real app theme/localizations, matching how every screen actually
/// renders — goldens are only meaningful if they use the same theme/fonts production does.
Widget wrapForGolden(Widget child, {Locale locale = const Locale('ar')}) {
  return MaterialApp(
    theme: AppTheme.light(),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    debugShowCheckedModeBanner: false,
    home: Material(color: AppColors.background, child: child),
  );
}

/// `matchesGoldenFile` alone leaves image decoding pending after `pumpWidget` — this drains
/// that so the captured frame has real pixels, not a placeholder.
Future<void> settleImages(WidgetTester tester) async {
  await tester.pumpAndSettle();
}
