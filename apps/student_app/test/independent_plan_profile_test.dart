import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/profile/presentation/student_profile_page.dart';

void main() {
  testWidgets('independent free plan can start a trial from Me', (tester) async {
    final access = FakeIndependentAccessRepository(
      plan: const IndependentPlanSnapshot(kind: IndependentPlanKind.free),
    );
    final profile = FakeStudentProfileRepository();
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: Scaffold(
            body: StudentProfilePage(
              repository: profile,
              principal: SessionPrincipal.independent().copyWith(userId: 'u1'),
              accessRepository: access,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Free'), findsWidgets);
    expect(find.text('Start free trial'), findsOneWidget);

    await tester.tap(find.text('Start free trial'));
    await tester.pumpAndSettle();

    expect(find.text('Trial'), findsWidgets);
    expect(find.text('Start free trial'), findsNothing);
    expect((await access.loadPlan(userId: 'u1')).kind, IndependentPlanKind.trial);
  });
}
