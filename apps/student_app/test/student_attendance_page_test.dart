import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/flex/presentation/student_attendance_page.dart';

void main() {
  testWidgets('shows month summary and day statuses', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: StudentAttendancePage(
            repository: FakeStudentAttendanceRepository(),
            initialMonth: DateTime.utc(2026, 8, 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Attendance'), findsWidgets);
    expect(find.textContaining('Present 1'), findsOneWidget);
    expect(find.text('2026-08-02'), findsOneWidget);
    expect(find.text('Late'), findsOneWidget);
  });
}
