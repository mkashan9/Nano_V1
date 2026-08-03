import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/parent/presentation/guardian_link_page.dart';
import 'package:student_app/features/profile/presentation/student_profile_page.dart';

void main() {
  testWidgets('create invite then demo accept then revoke', (tester) async {
    final repo = FakeGuardianLinkRepository();
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: GuardianLinkPage(
            repository: repo,
            childUserId: 'child-1',
            childDisplayName: 'Ali',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create invite'));
    await tester.pumpAndSettle();
    expect(find.text('GUARD01'), findsOneWidget);

    await tester.tap(find.text('Demo: accept as guardian'));
    await tester.pumpAndSettle();
    expect(find.text('Demo guardian'), findsOneWidget);

    await tester.tap(find.text('Revoke'));
    await tester.pumpAndSettle();
    expect(find.text('No guardians linked yet'), findsOneWidget);
  });

  testWidgets('profile opens guardian links from Me', (tester) async {
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
              guardianLinkRepository: FakeGuardianLinkRepository(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardian links'));
    await tester.pumpAndSettle();
    expect(find.text('Create invite'), findsOneWidget);
  });
}
