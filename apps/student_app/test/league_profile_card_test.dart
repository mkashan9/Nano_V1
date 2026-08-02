import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/profile/presentation/student_profile_page.dart';

void main() {
  testWidgets('profile shows join CTA then league rank after join',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final leagues = FakeLeagueRepository();
    final principal = SessionPrincipal.junior(displayName: 'Ali Alpha')
        .copyWith(userId: TenancyFixtures.aliAlphaId, isAuthenticated: true);

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: Scaffold(
            body: StudentProfilePage(
              repository: FakeStudentProfileRepository(
                sessions: [
                  SecurityFixtures.activeSession.copyWith(isCurrent: true),
                ],
              ),
              principal: principal,
              preferences: StudentPreferences(userId: principal.userId!),
              leagueRepository: leagues,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weekly league'), findsOneWidget);
    expect(find.text('Join this week'), findsOneWidget);

    await tester.tap(find.text('Join this week'));
    await tester.pumpAndSettle();

    expect(leagues.joinCalls, 1);
    expect(find.textContaining('Bronze · #2 of 5'), findsOneWidget);
    expect(find.textContaining('40 XP this week'), findsOneWidget);
  });
}
