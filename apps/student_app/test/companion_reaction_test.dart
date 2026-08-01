import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/quiz/presentation/junior_quiz_page.dart';
import 'package:student_app/features/quiz/presentation/senior_quiz_page.dart';

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

Widget _junior() => JuniorQuizPage(
      topicVersionId: _counting,
      repository: FakeLearnerQuizRepository(),
      attemptRepository: FakeQuizAttemptRepository(),
    );

Widget _senior() => SeniorQuizPage(
      topicVersionId: _counting,
      repository: FakeLearnerQuizRepository(),
      attemptRepository: FakeQuizAttemptRepository(),
    );

Future<void> _finishJunior(
  WidgetTester tester, {
  bool correctly = true,
}) async {
  await tester.tap(find.text(correctly ? 'Five' : 'Three'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(correctly ? '5' : '4'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Finish'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a passed attempt is celebrated', (tester) async {
    await _pump(tester, _junior());
    await _finishJunior(tester);

    expect(find.byType(CompanionStage), findsOneWidget);
    expect(find.byIcon(Icons.celebration_rounded), findsOneWidget);
    expect(find.textContaining('Nicely done!'), findsOneWidget);
  });

  testWidgets('a failed attempt gets a gentle retry, not a scolding',
      (tester) async {
    await _pump(tester, _junior());
    await _finishJunior(tester, correctly: false);

    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(
      find.textContaining('Some of these need another look.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.celebration_rounded), findsNothing);
  });

  testWidgets('the companion stays quiet before a result exists',
      (tester) async {
    await _pump(tester, _junior());

    expect(find.byType(CompanionStage), findsNothing);

    await tester.tap(find.text('Five'));
    await tester.pumpAndSettle();

    expect(find.byType(CompanionStage), findsNothing);
  });

  testWidgets('classroom mode keeps the caption and mutes the voice',
      (tester) async {
    await _pump(
      tester,
      _junior(),
      preferences: const AccessibilityPreferences(classroomMode: true),
    );
    await _finishJunior(tester);

    final stage = tester.widget<CompanionStage>(find.byType(CompanionStage));
    expect(stage.reaction!.speaks, isFalse);
    expect(stage.reaction!.tier, CompanionAssetTier.staticArt);
    expect(find.textContaining('Nicely done!'), findsOneWidget);
  });

  testWidgets('senior results react too, at senior density', (tester) async {
    await _pump(tester, _senior());

    await tester.tap(find.text('Five'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review & finish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Question 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review & finish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    final stage = tester.widget<CompanionStage>(find.byType(CompanionStage));
    expect(stage.reaction!.prominent, isFalse);
    expect(stage.reaction!.mood, CompanionMood.celebration);
  });
}
