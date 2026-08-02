import 'package:admin_web/features/school/presentation/academic_structure_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  testWidgets('shows academic structure and create actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.schoolAdmin(),
          home: AcademicStructurePage(
            repository: FakeAcademicStructureRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Classes'), findsWidgets);
    expect(find.text('Grade 5'), findsOneWidget);
    expect(find.text('5-A'), findsOneWidget);
    expect(find.text('Mathematics (MATH)'), findsOneWidget);
    expect(find.text('Add grade'), findsOneWidget);
  });

  testWidgets('empty school still shows Add grade / Add class', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.schoolAdmin(),
          home: AcademicStructurePage(
            repository: FakeAcademicStructureRepository(
              seed: const AcademicStructure(
                schoolId: TenancyFixtures.alphaSchoolId,
                gradeLevels: [],
                classes: [],
                sections: [],
                subjects: [],
                classSubjects: [],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add grade'), findsOneWidget);
    expect(find.text('Add class'), findsOneWidget);
    expect(find.text('Add subject'), findsOneWidget);
  });
}
