import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/flex/presentation/student_classroom_page.dart';

void main() {
  testWidgets('shows feed and acknowledges an item', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: StudentClassroomPage(
            repository: FakeStudentClassroomRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Classroom'), findsWidgets);
    expect(find.text('Bring notebooks'), findsOneWidget);
    expect(find.text('Acknowledge'), findsOneWidget);

    await tester.tap(find.text('Acknowledge'));
    await tester.pumpAndSettle();
    expect(find.text('Acknowledged.'), findsOneWidget);
  });
}
