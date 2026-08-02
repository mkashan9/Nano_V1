import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/features/marks/presentation/teacher_marks_page.dart';

void main() {
  testWidgets('shows marks page and saves draft assessment', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
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
    expect(find.text('Save draft'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Chapter 1 Quiz');
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();

    expect(find.text('Draft assessment saved.'), findsOneWidget);
    expect(find.textContaining('Chapter 1 Quiz'), findsWidgets);
  });
}
