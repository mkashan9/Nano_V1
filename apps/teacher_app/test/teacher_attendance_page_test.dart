import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/features/attendance/presentation/teacher_attendance_page.dart';

void main() {
  testWidgets('shows attendance grid and mark all present', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.teacher(),
          home: TeacherAttendancePage(
            repository: FakeTeacherAttendanceRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Mark all present'), findsOneWidget);
    expect(find.textContaining('Ali Khan'), findsOneWidget);

    await tester.tap(find.text('Mark all present'));
    await tester.pump();
    expect(find.text('Present'), findsWidgets);
  });
}
