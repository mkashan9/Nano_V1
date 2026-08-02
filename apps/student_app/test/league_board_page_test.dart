import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/league/presentation/league_board_page.dart';
import 'package:student_app/features/profile/presentation/student_profile_page.dart';

void main() {
  testWidgets('board challenges peer and opens challenges inbox',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final leagues = FakeLeagueRepository(
      status: LeagueStatus(
        joined: true,
        weekKey: '2026-W31',
        startsAt: DateTime.utc(2026, 7, 27),
        endsAt: DateTime.utc(2026, 8, 3),
        status: 'open',
        weekXp: 40,
        rank: 2,
        peerCount: 5,
        divisionSlug: 'bronze',
        divisionTitleEn: 'Bronze',
        divisionTitleUr: 'کانسی',
      ),
      board: const LeagueBoard(
        joined: true,
        weekKey: '2026-W31',
        myRank: 2,
        myWeekXp: 40,
        divisionSlug: 'bronze',
        divisionTitleEn: 'Bronze',
        entries: [
          LeagueBoardEntry(
            rank: 1,
            weekXp: 80,
            displayLabel: 'Sara',
            targetToken: 'tok-sara',
          ),
          LeagueBoardEntry(
            rank: 2,
            weekXp: 40,
            displayLabel: 'Ali',
            isMe: true,
          ),
        ],
      ),
    );
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
    await tester.tap(find.text('View board'));
    await tester.pumpAndSettle();

    expect(find.text('Challenge'), findsOneWidget);
    await tester.tap(find.text('Challenge'));
    await tester.pumpAndSettle();
    expect(leagues.challengeCalls, 1);
    expect(find.text('Challenge sent.'), findsOneWidget);

    await tester.tap(find.text('Challenges'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Number Rush duel'), findsOneWidget);
    expect(find.textContaining('Sara'), findsWidgets);
  });

  testWidgets('board page shows must-join when not joined', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: LeagueBoardPage(repository: FakeLeagueRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Join this week'), findsOneWidget);
  });
}
