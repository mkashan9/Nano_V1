import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/features/marks/presentation/teacher_marks_page.dart';

void main() {
  testWidgets('creates draft and opens marks grid', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1800));
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
    expect(find.text('Enter marks'), findsOneWidget);

    await tester.tap(find.text('Enter marks'));
    await tester.pumpAndSettle();

    expect(find.text('Marks grid'), findsOneWidget);
    expect(find.text('Save marks'), findsOneWidget);
    expect(find.text('Load template'), findsOneWidget);

    await tester.tap(find.text('Load template'));
    await tester.pumpAndSettle();
    expect(find.textContaining('student_user_id'), findsWidgets);

    await tester.tap(find.text('Preview import'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ok'), findsWidgets);

    await tester.ensureVisible(find.text('Commit import'));
    await tester.tap(find.text('Commit import'));
    await tester.pumpAndSettle();
    expect(find.text('Import committed.'), findsOneWidget);
  });
}
