import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/home/fixtures/student_home_fixtures.dart';
import 'package:student_app/features/home/presentation/junior_home_page.dart';
import 'package:student_app/features/home/presentation/senior_home_page.dart';
import 'package:student_app/features/learning/presentation/learning_progress_page.dart';

var _now = DateTime.utc(2026, 8, 1, 9);

CompanionController _controller({
  bool junior = true,
  AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
}) {
  return CompanionController(
    junior: junior,
    preferences: preferences,
    clock: () => _now,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  required CompanionController companion,
  bool junior = true,
  AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    NanoLocaleScope(
      locale: NanoAppLocale.en,
      copy: const NanoCopy(NanoAppLocale.en),
      child: NanoAccessibilityScope(
        preferences: preferences,
        feedback: NanoFeedback(preferences: preferences),
        child: NanoCompanionScope(
          controller: companion,
          child: MaterialApp(
            theme: junior ? NanoTheme.junior() : NanoTheme.senior(),
            home: Scaffold(body: page),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FakeStudentHomeRepository _homeRepo() => FakeStudentHomeRepository(
      subjects: StudentHomeFixtures.subjects,
      missions: StudentHomeFixtures.missions,
    );

void main() {
  setUp(() => _now = DateTime.utc(2026, 8, 1, 9));

  testWidgets('junior home leads with a hero companion', (tester) async {
    final companion = _controller();
    addTearDown(companion.dispose);
    await _pump(
      tester,
      JuniorHomePage(
        repository: _homeRepo(),
        learnerName: 'Ali',
        userId: 'u1',
      ),
      companion: companion,
    );

    expect(companion.reaction!.mood, CompanionMood.greeting);
    expect(companion.reaction!.mode, CompanionMode.guide);
    expect(find.text('Hi Ali'), findsOneWidget);
    expect(
      tester.getSize(find.byType(CompanionSlot)).width,
      CompanionStage.artSizeFor(
        placement: CompanionPlacement.hero,
        prominent: true,
        storyCard: false,
      ),
    );
  });

  testWidgets('senior home is not greeted on every visit', (tester) async {
    final companion = _controller(junior: false);
    addTearDown(companion.dispose);
    await _pump(
      tester,
      SeniorHomePage(
        repository: _homeRepo(),
        learnerName: 'Sara',
        userId: 'u2',
      ),
      companion: companion,
      junior: false,
    );

    expect(companion.reaction, isNull);
    expect(find.byType(CompanionSlot), findsNothing);
    expect(find.text('Hi Sara'), findsOneWidget);
  });

  testWidgets('coming back after a while is greeted on senior home',
      (tester) async {
    final companion = _controller(junior: false);
    addTearDown(companion.dispose);
    await _pump(
      tester,
      SeniorHomePage(
        repository: _homeRepo(),
        learnerName: 'Sara',
        userId: 'u2',
      ),
      companion: companion,
      junior: false,
    );

    _now = _now.add(const Duration(hours: 6));
    companion.appResumed();
    await tester.pumpAndSettle();

    expect(companion.reaction!.event, CompanionEvent.returnFromInactivity);
    expect(
      tester.getSize(find.byType(CompanionSlot)).width,
      CompanionStage.artSizeFor(
        placement: CompanionPlacement.aside,
        prominent: false,
        storyCard: false,
      ),
    );
  });

  testWidgets('an empty recommendation list gets a companion, not a blank panel',
      (tester) async {
    final companion = _controller();
    addTearDown(companion.dispose);
    await _pump(
      tester,
      LearningProgressPage(
        repository: FakeLearningInsightsRepository(allFinished: true),
        junior: true,
      ),
      companion: companion,
    );

    expect(find.text('Everything is finished. Well done.'), findsOneWidget);
    expect(companion.reaction!.event, CompanionEvent.emptyState);
    expect(companion.reaction!.mode, CompanionMode.guide);
  });

  testWidgets('classroom mode leaves the home layout intact and quiet',
      (tester) async {
    const preferences = AccessibilityPreferences(classroomMode: true);
    final companion = _controller(preferences: preferences);
    addTearDown(companion.dispose);
    await _pump(
      tester,
      JuniorHomePage(
        repository: _homeRepo(),
        learnerName: 'Ali',
        userId: 'u1',
      ),
      companion: companion,
      preferences: preferences,
    );

    expect(companion.reaction, isNull);
    expect(find.byType(CompanionSlot), findsNothing);
    expect(find.text('Hi Ali'), findsOneWidget);
    expect(find.text('Math'), findsOneWidget);
  });
}
