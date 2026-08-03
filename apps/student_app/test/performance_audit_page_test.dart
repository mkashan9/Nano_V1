import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/profile/presentation/student_profile_page.dart';
import 'package:student_app/features/qa/presentation/performance_audit_page.dart';

void main() {
  testWidgets('performance audit page passes at small-phone size',
      (tester) async {
    await tester.binding.setSurfaceSize(
      const Size(
        PerformanceViewports.smallPhoneWidth,
        PerformanceViewports.smallPhoneHeight,
      ),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(
              PerformanceViewports.smallPhoneWidth,
              PerformanceViewports.smallPhoneHeight,
            ),
            textScaler: TextScaler.linear(PerformanceViewports.textScaleSmoke),
          ),
          child: MaterialApp(
            theme: NanoTheme.junior(),
            home: PerformanceAuditPage(
              repository: FakePerformanceAuditRepository(),
              width: PerformanceViewports.smallPhoneWidth,
              textScale: PerformanceViewports.textScaleSmoke,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Performance & small device'), findsOneWidget);
    expect(find.text('All performance checks passed'), findsOneWidget);
  });

  testWidgets('profile opens performance audit from Me', (tester) async {
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
    await tester.tap(find.text('Performance & small device'));
    await tester.pumpAndSettle();
    expect(find.text('All performance checks passed'), findsOneWidget);
  });

  test('layout policy matches NanoResponsive phone columns', () {
    expect(
      PerformanceLayoutPolicy.subjectColumns(
        width: NanoBreakpoints.smallPhone,
        junior: true,
      ),
      NanoResponsive.subjectColumnsFor(
        size: NanoWindowSize.phone,
        junior: true,
      ),
    );
    expect(
      PerformanceLayoutPolicy.subjectColumns(
        width: NanoBreakpoints.smallPhone,
        junior: false,
      ),
      NanoResponsive.subjectColumnsFor(
        size: NanoWindowSize.phone,
        junior: false,
      ),
    );
  });
}
