import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/onboarding/presentation/onboarding_flow_page.dart';
import 'package:student_app/features/quiz/presentation/junior_quiz_page.dart';

const _counting = 'tv-counting-1';

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    NanoLocaleScope(
      locale: NanoAppLocale.en,
      copy: NanoCopy(NanoAppLocale.en),
      child: NanoAccessibilityScope(
        preferences: preferences,
        feedback: NanoFeedback(preferences: preferences),
        child: MaterialApp(home: page),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _finishJuniorQuiz(WidgetTester tester) async {
  await tester.tap(find.text('Five'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('5'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Finish'));
  await tester.pumpAndSettle();
}

Widget _onboarding({
  String companionName = 'Nori',
  AccessibilityPreferences accessibility = AccessibilityPreferences.defaults,
}) {
  const principal = SessionPrincipal(
    role: AppRole.independentStudent,
    userId: 'learner-1',
    displayName: 'Ayesha',
  );
  return OnboardingFlowPage(
    repository: FakeOnboardingRepository(),
    progress: const OnboardingProgress(userId: 'learner-1'),
    principal: principal,
    preferences: StudentPreferences(
      userId: 'learner-1',
      companionName: companionName,
      accessibility: accessibility,
    ),
    onProgressChanged: (_) {},
    onCompleted: (_, _) {},
  );
}

void main() {
  testWidgets('quiz results are coached, not turned into a milestone',
      (tester) async {
    await _pump(
      tester,
      JuniorQuizPage(
        topicVersionId: _counting,
        repository: FakeLearnerQuizRepository(),
        attemptRepository: FakeQuizAttemptRepository(),
      ),
    );
    await _finishJuniorQuiz(tester);

    final stage = tester.widget<CompanionStage>(find.byType(CompanionStage));
    expect(stage.reaction!.mode, CompanionMode.quizCoach);
    expect(stage.reaction!.presentation, CompanionPresentation.inline);
    expect(find.text('Nori · Quiz coach'), findsOneWidget);
  });

  testWidgets('the first opening is a framed story card', (tester) async {
    await _pump(tester, _onboarding());

    final stage = tester.widget<CompanionStage>(find.byType(CompanionStage));
    expect(stage.reaction!.presentation, CompanionPresentation.storyCard);
    expect(stage.reaction!.mode, CompanionMode.guide);
    expect(find.text('Nori · Guide'), findsOneWidget);
  });

  testWidgets('a renamed companion is named in its own badge', (tester) async {
    await _pump(tester, _onboarding(companionName: 'Bao'));

    expect(find.text('Bao · Guide'), findsOneWidget);
  });

  testWidgets('classroom mode holds back the welcome without shifting layout',
      (tester) async {
    // Onboarding reads the learner's own saved preferences, since the flow is
    // where they are set.
    await _pump(
      tester,
      _onboarding(
        accessibility: const AccessibilityPreferences(classroomMode: true),
      ),
    );

    final stage = tester.widget<CompanionStage>(find.byType(CompanionStage));
    expect(stage.reaction, isNull);
    expect(find.textContaining('Guide'), findsNothing);
    // The step itself still explains itself in words.
    expect(find.textContaining('Ayesha'), findsOneWidget);
  });
}
