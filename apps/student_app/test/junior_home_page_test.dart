import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/home/fixtures/student_home_fixtures.dart';
import 'package:student_app/features/home/presentation/junior_home_page.dart';

Widget _host({
  required StudentHomeRepository repository,
  String companionName = 'Nori',
  bool showMissions = false,
  ValueChanged<ContinueLearningItem>? onContinue,
  ValueChanged<LearningSubject>? onSubjectTap,
}) {
  return NanoLocaleScope(
    locale: NanoAppLocale.en,
    copy: const NanoCopy(NanoAppLocale.en),
    child: MaterialApp(
      theme: NanoTheme.junior(),
      home: Scaffold(
        body: JuniorHomePage(
          repository: repository,
          learnerName: 'Ali',
          userId: 'u1',
          companionName: companionName,
          onContinue: onContinue,
          onSubjectTap: onSubjectTap,
          onNotifications: () {},
          showMissions: showMissions,
          useVisualAssets: false,
        ),
      ),
    ),
  );
}

FakeStudentHomeRepository _repo({
  bool failOnce = false,
  bool servesCache = false,
  HomeNoticeKind notice = HomeNoticeKind.none,
  List<LearningSubject> subjects = StudentHomeFixtures.subjects,
}) {
  return FakeStudentHomeRepository(
    failOnce: failOnce,
    servesCache: servesCache,
    notice: notice,
    subjects: subjects,
    missions: StudentHomeFixtures.missions,
  );
}

void main() {
  testWidgets('loads greeting, continue hero and subjects', (tester) async {
    await tester.pumpWidget(_host(repository: _repo()));
    await tester.pumpAndSettle();

    expect(find.text('Hi Ali'), findsOneWidget);
    expect(find.text('Animals Adventure'), findsOneWidget);
    expect(find.text('Continue Learning'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Math'), findsOneWidget);
    expect(find.text("Today's Mission"), findsNothing);
  });

  testWidgets('missions appear when showMissions is enabled', (tester) async {
    await tester.pumpWidget(
      _host(repository: _repo(), showMissions: true),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's Mission"), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsNWidgets(3));
  });

  testWidgets('tapping Start reports the resumable lesson', (tester) async {
    ContinueLearningItem? tapped;
    await tester.pumpWidget(
      _host(repository: _repo(), onContinue: (item) => tapped = item),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(tapped?.id, 'lesson-animals');
  });

  testWidgets('failure shows a retry that recovers content', (tester) async {
    await tester.pumpWidget(_host(repository: _repo(failOnce: true)));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Hi Ali'), findsOneWidget);
  });

  testWidgets('cached data keeps content and shows when it was updated',
      (tester) async {
    await tester.pumpWidget(_host(repository: _repo(servesCache: true)));
    await tester.pumpAndSettle();

    expect(find.text('Hi Ali'), findsOneWidget);
    expect(find.text('Animals Adventure'), findsOneWidget);
  });

  testWidgets('maintenance blocks the junior home', (tester) async {
    await tester.pumpWidget(
      _host(
        repository: _repo(notice: HomeNoticeKind.maintenance),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('maintenance'), findsOneWidget);
  });
}
