import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/app/sync_preview_page.dart';

void main() {
  testWidgets('sync preview shows cache and pending draft', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SyncPreviewPage()));
    expect(find.text('Offline & drafts'), findsOneWidget);
    expect(find.textContaining('Pending changes'), findsOneWidget);
    expect(find.text('Simulate newer saved version'), findsOneWidget);

    await tester.tap(find.text('Simulate newer saved version'));
    await tester.pump();
    expect(find.text('Keep saved version'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
  });
}
