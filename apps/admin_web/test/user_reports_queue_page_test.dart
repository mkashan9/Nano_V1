import 'package:admin_web/features/moderation/presentation/user_reports_queue_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('queue lists open reports and resolves with a note',
      (tester) async {
    final repo = FakeModerationQueueRepository();
    await tester.binding.setSurfaceSize(const Size(1400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(home: UserReportsQueuePage(repository: repo)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('User reports'), findsOneWidget);
    expect(find.text('sara'), findsWidgets);

    await tester.tap(find.text('sara').first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Reviewed — no action');
    await tester.tap(find.text('Resolve'));
    await tester.pumpAndSettle();

    expect(find.text('Report closed'), findsOneWidget);
  });
}
