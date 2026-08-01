import 'package:admin_web/features/content/presentation/topic_quiz_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

Future<void> _pump(
  WidgetTester tester, {
  required TopicQuizRepository repository,
  QuestionBankRepository? questionBank,
  NanoAppLocale locale = NanoAppLocale.en,
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    NanoLocaleScope(
      locale: locale,
      copy: NanoCopy(locale),
      child: MaterialApp(
        home: TopicQuizPage(
          repository: repository,
          questionBank: questionBank ?? FakeQuestionBankRepository(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists seeded quizzes with status', (tester) async {
    await _pump(tester, repository: FakeTopicQuizRepository());

    expect(find.text('Topic quizzes'), findsOneWidget);
    expect(find.textContaining('Counting check'), findsWidgets);
    expect(find.textContaining('Published'), findsWidgets);
  });

  testWidgets('Junior and Senior previews share the same version id',
      (tester) async {
    await _pump(tester, repository: FakeTopicQuizRepository());

    expect(find.text('Junior preview'), findsOneWidget);
    expect(find.text('Senior preview'), findsOneWidget);
    // Topic slug order selects addition first.
    expect(
      find.textContaining('60000000-0000-0000-0000-000000000002'),
      findsNWidgets(3),
    );
  });

  testWidgets('new quiz creates a draft', (tester) async {
    final repository = FakeTopicQuizRepository();
    await _pump(tester, repository: repository);

    await tester.tap(find.text('New quiz'));
    await tester.pumpAndSettle();

    expect(repository.createCount, 1);
    expect(find.textContaining('Ecosystems check'), findsWidgets);
  });

  testWidgets('publish turns a draft into published', (tester) async {
    final repository = FakeTopicQuizRepository(seed: [
      TopicQuiz(
        id: 'draft-1',
        topicVersionId: 'topic-draft',
        topicSlug: 'draft-topic',
        topicTitle: 'Draft topic',
        status: QuestionStatus.draft,
        title: 'Draft quiz',
        items: const [
          QuizItem(
            sortOrder: 1,
            questionVersionId: '51000000-0000-0000-0000-000000000001',
            stem: 'Is this a draft quiz?',
            options: [
              QuestionOption(id: 'yes', label: 'Yes', isCorrect: true),
              QuestionOption(id: 'no', label: 'No'),
            ],
          ),
        ],
      ),
    ]);
    await _pump(tester, repository: repository);

    expect(find.text('Publish quiz'), findsOneWidget);
    await tester.tap(find.text('Publish quiz'));
    await tester.pumpAndSettle();

    expect(repository.publishCount, 1);
    expect(find.textContaining('Published'), findsWidgets);
  });

  testWidgets('Urdu shows the Urdu quiz title in the preview', (tester) async {
    await _pump(
      tester,
      repository: FakeTopicQuizRepository(),
      locale: NanoAppLocale.ur,
    );

    await tester.tap(find.text('Counting check'));
    await tester.pumpAndSettle();

    expect(find.textContaining('گنتی'), findsWidgets);
  });
}
