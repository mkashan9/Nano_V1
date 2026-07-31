import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/home/fixtures/student_home_fixtures.dart';
import 'package:student_app/features/home/presentation/senior_home_page.dart';

Widget _host({
  required StudentHomeRepository repository,
  bool flexEligible = false,
  VoidCallback? onOpenFlex,
  ValueChanged<ContinueLearningItem>? onContinue,
  NanoAppLocale locale = NanoAppLocale.en,
}) {
  return NanoLocaleScope(
    locale: locale,
    copy: NanoCopy(locale),
    child: MaterialApp(
      theme: NanoTheme.senior(),
      home: Scaffold(
        body: SeniorHomePage(
          repository: repository,
          learnerName: 'Sara',
          userId: 'u1',
          flexEligible: flexEligible,
          onOpenFlex: onOpenFlex,
          onContinue: onContinue,
          onSubjectTap: (_) {},
          onOpenUpdate: () {},
          onNotifications: () {},
        ),
      ),
    ),
  );
}

/// Senior home is a long scroll; a taller surface keeps every section built
/// so tests assert on content rather than on scroll position.
Future<void> _pump(WidgetTester tester, Widget app) async {
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

FakeStudentHomeRepository _repo({
  bool failOnce = false,
  bool servesCache = false,
  HomeNoticeKind notice = HomeNoticeKind.none,
  Set<HomeSection> failSections = const {},
}) {
  return FakeStudentHomeRepository(
    failOnce: failOnce,
    servesCache: servesCache,
    notice: notice,
    failSections: failSections,
    subjects: StudentHomeFixtures.subjects,
    missions: StudentHomeFixtures.missions,
  );
}

void main() {
  testWidgets('shows level, streak, XP and the plan', (tester) async {
    await _pump(tester, _host(repository: _repo()));
    await tester.pumpAndSettle();

    expect(find.text('Hi Sara'), findsOneWidget);
    expect(find.textContaining('Level 3'), findsOneWidget);
    expect(find.textContaining('7 day streak'), findsOneWidget);
    expect(find.text('190 XP to next level'), findsOneWidget);
    expect(find.text("Today's Plan"), findsOneWidget);
    expect(find.textContaining('Complete a lesson'), findsOneWidget);
  });

  testWidgets('senior plan shows every mission, unlike junior', (tester) async {
    await _pump(tester, _host(repository: _repo()));
    await tester.pumpAndSettle();

    for (final mission in StudentHomeFixtures.missions) {
      expect(find.text(mission.title), findsOneWidget);
    }
  });

  testWidgets('ineligible learner never sees a flex card', (tester) async {
    await _pump(tester, _host(repository: _repo()));

    expect(find.text('Flex'), findsNothing);
    expect(find.textContaining('tasks open'), findsNothing);
  });

  testWidgets('eligible learner sees the flex summary', (tester) async {
    await _pump(tester, _host(repository: _repo(), flexEligible: true));

    expect(find.text('Flex'), findsOneWidget);
    expect(find.textContaining('3 tasks open'), findsOneWidget);
    expect(find.textContaining('Due Friday'), findsOneWidget);
  });

  testWidgets('flex card deep-links out', (tester) async {
    var opened = 0;
    await _pump(
      tester,
      _host(
        repository: _repo(),
        flexEligible: true,
        onOpenFlex: () => opened++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Flex'));
    await tester.pumpAndSettle();

    expect(opened, 1);
  });

  testWidgets('continue card reports the resumable item', (tester) async {
    ContinueLearningItem? tapped;
    await _pump(
      tester,
      _host(repository: _repo(), onContinue: (item) => tapped = item),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Animals Adventure'));
    await tester.pumpAndSettle();

    expect(tapped?.id, 'lesson-animals');
  });

  testWidgets('one failed section leaves the rest of the home intact',
      (tester) async {
    await _pump(
      tester,
      _host(
        repository: _repo(failSections: const {HomeSection.subjects}),
        flexEligible: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining("Subjects — This part didn't load"),
        findsOneWidget);
    expect(find.text('Animals Adventure'), findsOneWidget);
    expect(find.text("Today's Plan"), findsOneWidget);
    expect(find.text('Flex'), findsOneWidget);
    expect(find.text('Something went wrong'), findsNothing);
  });

  testWidgets('failed section retry reloads the home', (tester) async {
    final repo = _repo(failSections: const {HomeSection.updates});
    await _pump(tester, _host(repository: repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('Latest update'), findsOneWidget);
    expect(repo.loadCount, 1);

    await tester.tap(find.widgetWithText(TextButton, 'Try again'));
    await tester.pumpAndSettle();

    expect(repo.loadCount, 2);
  });

  testWidgets('total failure shows the retry state', (tester) async {
    await _pump(tester, _host(repository: _repo(failOnce: true)));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Hi Sara'), findsOneWidget);
  });

  testWidgets('cached data keeps content with a timestamp', (tester) async {
    await _pump(tester, _host(repository: _repo(servesCache: true)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Last updated 3 h ago'), findsOneWidget);
    expect(find.text('Hi Sara'), findsOneWidget);
  });

  testWidgets('maintenance blocks the senior home', (tester) async {
    await _pump(
      tester,
      _host(repository: _repo(notice: HomeNoticeKind.maintenance)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Under maintenance'), findsOneWidget);
    expect(find.text('Hi Sara'), findsNothing);
  });

  testWidgets('urdu locale renders the plan heading in Urdu', (tester) async {
    await _pump(
      tester,
      _host(repository: _repo(), locale: NanoAppLocale.ur),
    );
    await tester.pumpAndSettle();

    expect(find.text('آج کا پلان'), findsOneWidget);
    expect(find.textContaining('لیول 3'), findsOneWidget);
  });
}
