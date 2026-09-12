import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Brief P12 item 4: "reduced-motion respected". [LoadingSkeleton] pulses via a repeating
/// [AnimationController] by default — these confirm it actually stops repeating (rather than
/// just looking static by coincidence at the moment a screenshot is taken) when the platform
/// reports `MediaQuery.disableAnimations`, and that it still pulses normally otherwise.
void main() {
  Widget wrap({required bool disableAnimations}) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: LoadingSkeleton(width: 100),
      ),
    );
  }

  testWidgets('pulses (opacity changes over time) when animations are enabled', (tester) async {
    await tester.pumpWidget(wrap(disableAnimations: false));
    await tester.pump();
    final opacityAt0 = tester.widget<Opacity>(find.byType(Opacity)).opacity;

    await tester.pump(const Duration(milliseconds: 450));
    final opacityLater = tester.widget<Opacity>(find.byType(Opacity)).opacity;

    expect(opacityLater, isNot(opacityAt0));
  });

  testWidgets('stays at a fixed opacity and never pulses when reduced motion is requested', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(disableAnimations: true));
    await tester.pump();
    final opacityAt0 = tester.widget<Opacity>(find.byType(Opacity)).opacity;

    await tester.pump(const Duration(milliseconds: 450));
    final opacityLater = tester.widget<Opacity>(find.byType(Opacity)).opacity;

    expect(opacityLater, opacityAt0);
  });
}
