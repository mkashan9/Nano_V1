import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/home/fixtures/student_home_fixtures.dart';
import 'package:student_app/features/home/presentation/junior_home_page.dart';
import 'package:student_app/features/learning/presentation/learning_progress_page.dart';
import 'package:student_app/features/onboarding/presentation/onboarding_flow_page.dart';
import 'package:student_app/features/quiz/presentation/junior_quiz_page.dart';

/// MED-12: every product surface the placement policy names actually mounts
/// the session companion. Game waits on GME-01 and is excluded on purpose.
var _now = DateTime.utc(2026, 8, 2, 9);

CompanionController _controller({bool junior = true}) {
  return CompanionController(
    junior: junior,
    clock: () => _now,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  required CompanionController companion,
  bool junior = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    NanoLocaleScope(
      locale: NanoAppLocale.en,
      copy: const NanoCopy(NanoAppLocale.en),
      child: NanoAccessibilityScope(
        preferences: AccessibilityPreferences.defaults,
        feedback: NanoFeedback(preferences: AccessibilityPreferences.defaults),
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
  await tester.pump(); // post-frame enterSurface
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUp(() => _now = DateTime.utc(2026, 8, 2, 9));

  test('the product surface set matches what MED-12 promised to mount', () {
    expect(
      CompanionCoverage.productSurfaces,
      {
        CompanionSurface.onboarding,
        CompanionSurface.home,
        CompanionSurface.learning,
        CompanionSurface.quiz,
        CompanionSurface.progress,
      },
    );
  });

  testWidgets('onboarding welcome uses the session companion', (tester) async {
    final companion = _controller();
    addTearDown(companion.dispose);
    await _pump(
      tester,
      OnboardingFlowPage(
        repository: FakeOnboardingRepository(),
        progress: const OnboardingProgress(userId: 'learner-1'),
        principal: const SessionPrincipal(
          role: AppRole.independentStudent,
          userId: 'learner-1',
          displayName: 'Ayesha',
        ),
        preferences: const StudentPreferences(userId: 'learner-1'),
        onProgressChanged: (_) {},
        onCompleted: (_, _) {},
      ),
      companion: companion,
    );

    expect(find.byType(CompanionSurfaceStage), findsOneWidget);
    expect(companion.surface, CompanionSurface.onboarding);
    expect(companion.reaction, isNotNull);
  });

  testWidgets('home mounts the session companion', (tester) async {
    final companion = _controller();
    addTearDown(companion.dispose);
    await _pump(
      tester,
      JuniorHomePage(
        repository: FakeStudentHomeRepository(
          subjects: StudentHomeFixtures.subjects,
          missions: StudentHomeFixtures.missions,
        ),
        learnerName: 'Ali',
        userId: 'u1',
      ),
      companion: companion,
    );

    expect(find.byType(CompanionSurfaceStage), findsOneWidget);
    expect(companion.surface, CompanionSurface.home);
  });

  testWidgets('quiz questions and results use the session companion',
      (tester) async {
    final companion = _controller();
    addTearDown(companion.dispose);
    await _pump(
      tester,
      JuniorQuizPage(
        topicVersionId: 'tv-counting-1',
        repository: FakeLearnerQuizRepository(),
        attemptRepository: FakeQuizAttemptRepository(),
      ),
      companion: companion,
    );

    expect(find.byType(CompanionSurfaceStage), findsOneWidget);
    expect(companion.surface, CompanionSurface.quiz);

    await tester.tap(find.text('Five'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.byType(CompanionSurfaceStage), findsWidgets);
    expect(companion.surface, CompanionSurface.quiz);
    expect(companion.reaction?.mood, CompanionMood.celebration);
  });

  testWidgets('progress empty state mounts the session companion',
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

    expect(find.byType(CompanionSurfaceStage), findsOneWidget);
    expect(companion.surface, CompanionSurface.progress);
  });

  testWidgets('a recovery action stays tappable under an error companion',
      (tester) async {
    final companion = _controller();
    addTearDown(companion.dispose);
    var retried = false;
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: NanoAccessibilityScope(
          preferences: AccessibilityPreferences.defaults,
          feedback:
              NanoFeedback(preferences: AccessibilityPreferences.defaults),
          child: NanoCompanionScope(
            controller: companion,
            child: MaterialApp(
              home: Scaffold(
                body: NanoViewStateHost(
                  state: const NanoViewError(),
                  onRetry: () => retried = true,
                  companionSurface: CompanionSurface.quiz,
                  junior: true,
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(CompanionSurfaceStage), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });
}
