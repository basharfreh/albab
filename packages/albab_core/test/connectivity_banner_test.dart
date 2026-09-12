import 'dart:async';

import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Brief P12 item 5: "a connectivity banner". [connectivityProvider] itself wraps the real
/// `connectivity_plus` plugin, which has no platform channel in a widget test — these
/// override it directly with a `Stream<bool>` rather than touching the plugin at all.
void main() {
  Widget wrap(Stream<bool> connectivity) {
    return ProviderScope(
      overrides: [connectivityProvider.overrideWith((ref) => connectivity)],
      child: MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ConnectivityBanner()),
      ),
    );
  }

  testWidgets('renders nothing while online', (tester) async {
    await tester.pumpWidget(wrap(Stream.value(true)));
    await tester.pump();

    expect(find.text('لا يوجد اتصال بالإنترنت'), findsNothing);
    expect(find.byIcon(Icons.wifi_off), findsNothing);
  });

  testWidgets('renders nothing while the initial state is still unknown', (tester) async {
    // A stream that hasn't emitted yet — `AsyncLoading`, not `AsyncData(false)`. No banner
    // flash on cold start before the platform has actually reported anything.
    await tester.pumpWidget(wrap(const Stream.empty()));
    await tester.pump();

    expect(find.text('لا يوجد اتصال بالإنترنت'), findsNothing);
  });

  testWidgets('shows the offline banner once the stream reports no connectivity', (
    tester,
  ) async {
    final controller = StreamController<bool>();
    addTearDown(controller.close);
    await tester.pumpWidget(wrap(controller.stream));
    await tester.pump();
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsNothing);

    controller.add(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);

    controller.add(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('لا يوجد اتصال بالإنترنت'), findsNothing);
  });
}
