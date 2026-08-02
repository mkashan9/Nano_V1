import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/features/classroom/presentation/teacher_classroom_page.dart';

void main() {
  testWidgets('creates draft and adds a link attachment', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
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

    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    expect(find.text('Attachments'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(2), 'Worksheet');
    await tester.enterText(fields.at(3), 'https://example.com/ws.pdf');
    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();

    expect(find.text('Attachment added.'), findsOneWidget);
    expect(find.text('Worksheet'), findsWidgets);
  });
}
