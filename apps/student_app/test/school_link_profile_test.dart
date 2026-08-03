import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/profile/presentation/student_profile_page.dart';

void main() {
  testWidgets('independent can preview and link a school invite', (tester) async {
    SessionPrincipal? linked;
    final linkRepo = FakeSchoolLinkRepository();
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: Scaffold(
            body: StudentProfilePage(
              repository: FakeStudentProfileRepository(),
              principal: SessionPrincipal.independent().copyWith(userId: 'u1'),
              schoolLinkRepository: linkRepo,
              onSchoolLinked: (next) => linked = next,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Link your school'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'ALPHA01');
    await tester.tap(find.text('Check code'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Alpha Academy'), findsOneWidget);
    await tester.tap(find.text('Link school'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Progress preserved'), findsOneWidget);
    expect(linked?.role, AppRole.seniorStudent);
    expect(linked?.schoolId, TenancyFixtures.alphaSchoolId);
    expect(linked?.flexEligible, isTrue);
  });
}
