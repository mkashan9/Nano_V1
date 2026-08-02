import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/features/classroom/presentation/teacher_classroom_page.dart';

void main() {
  testWidgets('creates a classroom draft announcement', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.teacher(),
          home: TeacherClassroomPage(
            repository: FakeTeacherClassroomRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Classroom'), findsWidgets);
    await tester.enterText(find.byType(TextField).first, 'Bring books');
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();

    expect(find.text('Announcement saved.'), findsOneWidget);
    expect(find.text('Bring books'), findsWidgets);
  });
}
