import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/safety/presentation/report_user_sheet.dart';

void main() {
  testWidgets('report sheet returns draft with category and block',
      (tester) async {
    ReportDraft? draft;

    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  draft = await showReportUserSheet(
                    context: context,
                    peerLabel: 'sara',
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Report learner'), findsOneWidget);
    await tester.tap(find.text('Spam'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'unwanted messages');
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(draft?.category, ReportCategory.spam);
    expect(draft?.details, 'unwanted messages');
    expect(draft?.alsoBlock, isTrue);
  });
}
