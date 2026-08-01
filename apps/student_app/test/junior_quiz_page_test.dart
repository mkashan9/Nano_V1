import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/quiz/presentation/junior_quiz_page.dart';

Future<void> _pump(
  WidgetTester tester, {
  required LearnerQuizRepository repository,
  String topicVersionId = '40000000-0000-0000-0000-000000000001',
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    NanoLocaleScope(
      locale: NanoAppLocale.en,
      copy: NanoCopy(NanoAppLocale.en),
      child: MaterialApp(
        home: JuniorQuizPage(
          topicVersionId: topicVersionId,
          repository: repository,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows one question with companion and options', (tester) async {
    await _pump(tester, repository: FakeLearnerQuizRepository());

    expect(find.byType(CompanionSlot), findsWidgets);
    expect(find.textContaining('How many apples'), findsOneWidget);
    expect(find.text('Question 1 of 2'), findsOneWidget);
    expect(find.text('Five'), findsOneWidget);
    expect(find.text('Correct answer'), findsNothing);
  });

  testWidgets('select and next advances without scoring', (tester) async {
    await _pump(tester, repository: FakeLearnerQuizRepository());

    await tester.tap(find.text('Five'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.textContaining('What is 2 + 3?'), findsOneWidget);
    expect(find.text('Question 2 of 2'), findsOneWidget);

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('You finished the quiz!'), findsOneWidget);
    expect(find.textContaining('Score:'), findsOneWidget);
    expect(find.text('This score was saved by the server.'), findsOneWidget);
  });

  testWidgets('missing quiz shows empty state', (tester) async {
    await _pump(
      tester,
      repository: FakeLearnerQuizRepository(),
      topicVersionId: '00000000-0000-0000-0000-000000000099',
    );

    expect(find.textContaining('No quiz'), findsWidgets);
  });
}
