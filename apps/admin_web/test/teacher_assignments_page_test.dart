import 'package:admin_web/features/school/presentation/teacher_assignments_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('shows assignments workload and assign action', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.schoolAdmin(),
          home: TeacherAssignmentsPage(
            repository: FakeTeacherAssignmentRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assignments'), findsWidgets);
    expect(find.text('Ms. Khan'), findsWidgets);
    expect(find.text('Assign'), findsOneWidget);
    expect(find.text('Workload'), findsOneWidget);
  });
}
