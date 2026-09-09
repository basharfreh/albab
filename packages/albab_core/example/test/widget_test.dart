import 'package:albab_core_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

// `LoadingSkeleton` in the gallery pulses forever (`AnimationController.repeat`), so
// `pumpAndSettle()` — which waits for every animation to finish — never returns here. A
// couple of bounded `pump()`s are enough to let providers/locale changes land instead.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUp(() {
    // `localeProvider` reads/writes `PrefsStorage` (shared_preferences) on build — widget
    // tests have no real platform channel to back it, so we fake the platform in-memory.
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('gallery renders RTL in Arabic (the default) with the app name visible', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GalleryApp()));
    await _settle(tester);

    expect(find.text('الباب العقاري'), findsOneWidget);
    final directionality = tester.widget<Directionality>(find.byType(Directionality).first);
    expect(directionality.textDirection, TextDirection.rtl);
  });

  testWidgets('the language toggle switches to English and flips to LTR', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GalleryApp()));
    await _settle(tester);

    await tester.tap(find.byIcon(Icons.language));
    await _settle(tester);

    expect(find.text('Al-Bab Real Estate'), findsOneWidget);
    final directionality = tester.widget<Directionality>(find.byType(Directionality).first);
    expect(directionality.textDirection, TextDirection.ltr);
  });
}
