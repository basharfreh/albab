import 'package:albab_core/albab_core.dart';
import 'package:albab_mobile/features/discovery/ui/widgets/map_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Widget _wrap(TextEditingController controller, ValueChanged<String> onSubmitted) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: MapSearchField(controller: controller, onSubmitted: onSubmitted)),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('submitting a search persists it and shows it as a recent search next time', (
    tester,
  ) async {
    final controller = TextEditingController();
    String? submitted;
    await tester.pumpWidget(_wrap(controller, (value) => submitted = value));

    await tester.enterText(find.byType(TextField), 'حي الحسين');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump();

    expect(submitted, 'حي الحسين');

    // Re-focusing an empty field now shows it in the recent-searches panel.
    controller.clear();
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(find.text('حي الحسين'), findsOneWidget);
  });

  testWidgets('tapping a recent search fills the field and resubmits it', (tester) async {
    final controller = TextEditingController();
    final submissions = <String>[];
    await tester.pumpWidget(_wrap(controller, submissions.add));

    await tester.enterText(find.byType(TextField), 'حي الزهراء');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    controller.clear();
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();

    await tester.tap(find.text('حي الزهراء'));
    await tester.pump();
    await tester.pump();

    expect(submissions, ['حي الزهراء', 'حي الزهراء']);
    expect(controller.text, 'حي الزهراء');
  });

  testWidgets('clearing recent searches removes the panel', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(_wrap(controller, (_) {}));

    await tester.enterText(find.byType(TextField), 'حي المشلب');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    controller.clear();
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(find.text('حي المشلب'), findsOneWidget);

    await tester.tap(find.text('مسح الكل'));
    await tester.pump();

    expect(find.text('حي المشلب'), findsNothing);
  });
}
