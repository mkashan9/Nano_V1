import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('host shows child when ready', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NanoViewStateHost(
            state: NanoViewReady(),
            child: Text('content'),
          ),
        ),
      ),
    );
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('host shows maintenance and error retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NanoViewStateHost(
            state: const NanoViewMaintenance(),
            onRetry: () => retried = true,
            child: const Text('hidden'),
          ),
        ),
      ),
    );
    expect(find.text('Under maintenance'), findsOneWidget);
    expect(find.text('hidden'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NanoViewStateHost(
            state: const NanoViewError(),
            onRetry: () => retried = true,
            child: const Text('hidden'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('offline keeps child visible under banner', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NanoViewStateHost(
            state: NanoViewOffline(lastUpdatedLabel: '2 min ago'),
            child: Text('cached'),
          ),
        ),
      ),
    );
    expect(find.textContaining('offline'), findsOneWidget);
    expect(find.textContaining('2 min ago'), findsOneWidget);
    expect(find.text('cached'), findsOneWidget);
  });
}
