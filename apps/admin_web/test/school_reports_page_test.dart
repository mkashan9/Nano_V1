import 'package:admin_web/features/school/presentation/school_reports_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('shows reports metrics and workload', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.schoolAdmin(),
          home: SchoolReportsPage(
            repository: FakeSchoolReportsRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reports'), findsWidgets);
    expect(find.text('Ms. Khan'), findsOneWidget);
    expect(find.text('Assignment coverage'), findsOneWidget);
    expect(find.text('Teacher workload'), findsOneWidget);
  });
}
