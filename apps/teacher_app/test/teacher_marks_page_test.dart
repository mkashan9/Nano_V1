import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/features/marks/presentation/teacher_marks_page.dart';

void main() {
  testWidgets('creates draft, imports, publishes, and corrects', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.teacher(),
          home: TeacherMarksPage(
            repository: FakeTeacherAssessmentRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marks'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Chapter 1 Quiz');
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();

    expect(find.text('Draft assessment saved.'), findsOneWidget);
    await tester.tap(find.text('Enter marks'));
    await tester.pumpAndSettle();

    expect(find.text('Marks grid'), findsOneWidget);
    expect(find.text('Load template'), findsOneWidget);

    await tester.tap(find.text('Load template'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview import'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Commit import'));
    await tester.tap(find.text('Commit import'));
    await tester.pumpAndSettle();
    expect(find.text('Import committed.'), findsOneWidget);

    await tester.ensureVisible(find.text('Publish marks'));
    await tester.tap(find.text('Publish marks'));
    await tester.pumpAndSettle();
    expect(find.text('Assessment published.'), findsOneWidget);
    expect(find.text('Result summary'), findsOneWidget);
    expect(find.text('Correction'), findsOneWidget);

    // Cycle not_submitted → scored → absent so correction needs no obtained marks.
    await tester.tap(find.widgetWithText(TextButton, 'Not submitted').first);
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Scored').first);
    await tester.pump();

    final reasonField = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          (w.decoration is InputDecoration) &&
          (w.decoration as InputDecoration).labelText == 'Correction reason',
    );
    await tester.enterText(reasonField, 'Parent called');
    await tester.pump();
    await tester.ensureVisible(find.text('Apply correction'));
    await tester.tap(find.text('Apply correction'));
    await tester.pumpAndSettle();
    expect(find.text('Correction saved.'), findsOneWidget);
  });
}
