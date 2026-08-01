import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/quiz/presentation/senior_quiz_page.dart';

Future<void> _pump(
  WidgetTester tester, {
  required LearnerQuizRepository repository,
  String topicVersionId = '40000000-0000-0000-0000-000000000001',
}) async {
  await tester.binding.setSurfaceSize(const Size(1100, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    NanoLocaleScope(
      locale: NanoAppLocale.en,
      copy: NanoCopy(NanoAppLocale.en),
      child: MaterialApp(
        home: SeniorQuizPage(
          topicVersionId: topicVersionId,
          repository: repository,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows navigator and denser senior options', (tester) async {
    await _pump(tester, repository: FakeLearnerQuizRepository());

    expect(find.text('Question navigator'), findsNothing);
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.textContaining('How many apples'), findsOneWidget);
    expect(find.text('Correct answer'), findsNothing);
    expect(find.text('0 of 2 answered'), findsOneWidget);
  });

  testWidgets('review blocks finish until all answered', (tester) async {
    await _pump(tester, repository: FakeLearnerQuizRepository());

    await tester.tap(find.text('Five'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review & finish'));
    await tester.pumpAndSettle();

    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Unanswered'), findsWidgets);

    final finish = find.widgetWithText(FilledButton, 'Finish');
    expect(tester.widget<FilledButton>(finish).onPressed, isNull);

    await tester.tap(find.text('Question 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review & finish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('You finished the quiz!'), findsOneWidget);
    expect(find.textContaining('Score:'), findsOneWidget);
    expect(find.text('This score was saved by the server.'), findsOneWidget);
  });

  testWidgets('jump chip moves without clearing answers', (tester) async {
    await _pump(tester, repository: FakeLearnerQuizRepository());

    await tester.tap(find.text('Five'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '2'));
    await tester.pumpAndSettle();
    expect(find.textContaining('What is 2 + 3?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('How many apples'), findsOneWidget);
    expect(find.text('1 of 2 answered'), findsOneWidget);
  });
}
