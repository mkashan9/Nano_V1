import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/profile/presentation/student_profile_page.dart';
import 'package:student_app/features/qa/presentation/accessibility_audit_page.dart';

void main() {
  testWidgets('accessibility audit page passes smoke', (tester) async {
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: AccessibilityAuditPage(
            repository: FakeAccessibilityAuditRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accessibility audit'), findsOneWidget);
    expect(find.text('All accessibility checks passed'), findsOneWidget);
  });

  testWidgets('profile opens accessibility audit from Me', (tester) async {
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
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accessibility audit'));
    await tester.pumpAndSettle();
    expect(find.text('All accessibility checks passed'), findsOneWidget);
  });

  test('documented tap floors match NanoTheme', () {
    expect(
      NanoTheme.junior().nano.minTapTarget,
      AccessibilityAuditBudgets.juniorMinTapTargetDp,
    );
    expect(
      NanoTheme.senior().nano.minTapTarget,
      AccessibilityAuditBudgets.seniorMinTapTargetDp,
    );
    expect(
      NanoTheme.schoolAdmin().nano.minTapTarget,
      AccessibilityAuditBudgets.adminMinTapTargetDp,
    );
  });
}
