import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/profile/presentation/student_profile_page.dart';
import 'package:student_app/features/qa/presentation/offline_network_audit_page.dart';

void main() {
  testWidgets('offline network audit page passes offline smoke',
      (tester) async {
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: OfflineNetworkAuditPage(
            repository: FakeOfflineNetworkAuditRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Offline & poor network'), findsOneWidget);
    expect(find.text('All offline checks passed'), findsOneWidget);
  });

  testWidgets('profile opens offline network audit from Me', (tester) async {
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
    await tester.tap(find.text('Offline & poor network'));
    await tester.pumpAndSettle();
    expect(find.text('All offline checks passed'), findsOneWidget);
  });

  testWidgets('poor quality segment refreshes checklist', (tester) async {
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: OfflineNetworkAuditPage(
            repository: FakeOfflineNetworkAuditRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Poor'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Network: Poor'), findsOneWidget);
    expect(find.text('All offline checks passed'), findsOneWidget);
  });
}
