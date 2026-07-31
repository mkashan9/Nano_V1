import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';

void main() {
  testWidgets('conflict banner exposes resolve actions', (tester) async {
    var retry = false;
    var discard = false;
    var keep = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NanoConflictBanner(
            message: 'A newer saved version exists.',
            onRetry: () => retry = true,
            onDiscard: () => discard = true,
            onKeepServer: () => keep = true,
          ),
        ),
      ),
    );
    expect(find.textContaining('newer saved version'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.tap(find.text('Discard'));
    await tester.tap(find.text('Keep saved version'));
    expect(retry && discard && keep, isTrue);
  });
}
