import 'package:admin_web/features/school/presentation/school_overview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('shows school metrics and setup', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.schoolAdmin(),
          home: SchoolOverviewPage(
            repository: FakeSchoolDashboardRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alpha Academy'), findsOneWidget);
    expect(find.text('Learners'), findsOneWidget);
    expect(find.text('Setup progress'), findsOneWidget);
    expect(find.text('Edit branding'), findsOneWidget);
  });
}
