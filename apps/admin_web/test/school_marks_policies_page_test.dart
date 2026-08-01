import 'package:admin_web/features/school/presentation/school_marks_policies_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('shows policies and periods', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.schoolAdmin(),
          home: SchoolMarksPoliciesPage(
            repository: FakeSchoolMarksPolicyRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marks and result policies'), findsOneWidget);
    expect(find.text('Term 1'), findsOneWidget);
    expect(find.text('Save policy'), findsOneWidget);
    expect(find.text('Result periods'), findsOneWidget);
  });
}
