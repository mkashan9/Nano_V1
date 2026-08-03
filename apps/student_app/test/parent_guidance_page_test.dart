import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/parent/presentation/parent_guidance_page.dart';
import 'package:student_app/features/profile/presentation/student_profile_page.dart';

void main() {
  testWidgets('parent guidance page shows weekly tip and privacy hint',
      (tester) async {
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: ParentGuidancePage(
            repository: FakeParentGuidanceRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('For parents this week'), findsOneWidget);
    expect(find.text('Keep the streak gentle'), findsOneWidget);
    expect(find.textContaining('Marks and private notes'), findsOneWidget);
  });

  testWidgets('profile opens parent guidance from Me', (tester) async {
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: Scaffold(
            body: StudentProfilePage(
              repository: FakeStudentProfileRepository(),
              principal: SessionPrincipal.seniorSchool().copyWith(userId: 'u1'),
              parentGuidanceRepository: FakeParentGuidanceRepository(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('For parents this week'));
    await tester.pumpAndSettle();
    expect(find.text('Keep the streak gentle'), findsOneWidget);
  });
}
