import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/app/states_preview_page.dart';

void main() {
  testWidgets('states preview can switch to maintenance', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: StatesPreviewPage()));
    await tester.pumpAndSettle();
    expect(find.text('Sample learning content'), findsOneWidget);

    await tester.ensureVisible(find.text('Maintenance'));
    await tester.tap(find.text('Maintenance'));
    await tester.pumpAndSettle();
    expect(find.text('Under maintenance'), findsOneWidget);
    expect(find.text('Sample learning content'), findsNothing);

    await tester.ensureVisible(find.text('Offline'));
    await tester.tap(find.text('Offline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Last updated 2 min ago'), findsOneWidget);
    expect(find.text('Sample learning content'), findsOneWidget);
  });
}
