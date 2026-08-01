import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/quiz/presentation/junior_quiz_page.dart';

const _counting = 'tv-counting-1';

Future<void> _pumpJunior(
  WidgetTester tester,
  QuizAttemptRepository attempts,
) async {
  await tester.binding.setSurfaceSize(const Size(900, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    NanoLocaleScope(
      locale: NanoAppLocale.en,
      copy: NanoCopy(NanoAppLocale.en),
      child: MaterialApp(
        home: JuniorQuizPage(
          topicVersionId: _counting,
          repository: FakeLearnerQuizRepository(),
          attemptRepository: attempts,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Answers both counting questions, wrongly when [correctly] is false.
Future<void> _finishQuiz(WidgetTester tester, {bool correctly = true}) async {
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
  testWidgets('a missed question shows the correct answer and why',
      (tester) async {
    await _pumpJunior(tester, FakeQuizAttemptRepository());
    await _finishQuiz(tester, correctly: false);

    expect(find.textContaining('Score: 0%'), findsOneWidget);
    expect(find.text('0 of 2 correct'), findsOneWidget);
    expect(find.text('Pass mark: 70%'), findsOneWidget);
    expect(find.textContaining('Your answer: Three'), findsOneWidget);
    expect(find.textContaining('Correct answer: Five'), findsOneWidget);
    expect(
      find.textContaining('Why: Counting to five means there are five.'),
      findsOneWidget,
    );
  });

  testWidgets('correct answers are named without a correction', (tester) async {
    await _pumpJunior(tester, FakeQuizAttemptRepository());
    await _finishQuiz(tester);

    expect(find.textContaining('Score: 100%'), findsOneWidget);
    expect(find.text('Passed'), findsOneWidget);
    expect(find.textContaining('Your answer: Five'), findsOneWidget);
    expect(find.textContaining('Correct answer:'), findsNothing);
  });

  testWidgets('explanations stay hidden until the quiz is submitted',
      (tester) async {
    await _pumpJunior(tester, FakeQuizAttemptRepository());

    expect(find.textContaining('Why:'), findsNothing);
    expect(find.textContaining('Correct answer'), findsNothing);

    await tester.tap(find.text('Five'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Why:'), findsNothing);
    expect(find.textContaining('Correct answer'), findsNothing);
  });

  testWidgets('a retake opens a fresh attempt', (tester) async {
    final attempts = FakeQuizAttemptRepository();
    await _pumpJunior(tester, attempts);
    await _finishQuiz(tester, correctly: false);

    expect(find.text('You can try again whenever you like.'), findsOneWidget);

    await tester.tap(find.text('Retake quiz'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Score:'), findsNothing);
    expect(find.text('Question 1 of 2'), findsOneWidget);

    await _finishQuiz(tester);
    expect(find.textContaining('Score: 100%'), findsOneWidget);
    expect((await attempts.history()).length, 2);
  });

  testWidgets('an exhausted retake budget disables the button', (tester) async {
    await _pumpJunior(tester, FakeQuizAttemptRepository(maxRetakes: 0));
    await _finishQuiz(tester, correctly: false);

    expect(find.text('No tries left'), findsOneWidget);
    final retake = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Retake quiz'),
    );
    expect(retake.onPressed, isNull);
  });
}
