import 'package:albab_mobile/features/auth/ui/widgets/otp_code_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('entering one digit per box completes with the joined code', (tester) async {
    String? completedCode;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OtpCodeField(onCompleted: (code) => completedCode = code)),
      ),
    );

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(6));
    for (var i = 0; i < 6; i++) {
      await tester.enterText(fields.at(i), '${i + 1}');
      await tester.pump();
    }

    expect(completedCode, '123456');
  });

  testWidgets('pasting all six digits into the first box completes it', (tester) async {
    String? completedCode;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OtpCodeField(onCompleted: (code) => completedCode = code)),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();

    expect(completedCode, '123456');
  });

  testWidgets('a partial code never fires onCompleted', (tester) async {
    var completedCallCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OtpCodeField(onCompleted: (_) => completedCallCount++)),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '1');
    await tester.pump();

    expect(completedCallCount, 0);
  });
}
