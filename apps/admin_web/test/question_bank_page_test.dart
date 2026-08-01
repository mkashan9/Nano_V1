import 'package:admin_web/features/content/presentation/question_bank_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

Future<void> _pump(
  WidgetTester tester, {
  required QuestionBankRepository repository,
  NanoAppLocale locale = NanoAppLocale.en,
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    NanoLocaleScope(
      locale: locale,
      copy: NanoCopy(locale),
      child: MaterialApp(
        home: QuestionBankPage(repository: repository),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists seeded questions with status', (tester) async {
    await _pump(tester, repository: FakeQuestionBankRepository());

    expect(find.text('Question bank'), findsOneWidget);
    expect(find.textContaining('How many apples'), findsWidgets);
    expect(find.textContaining('Published'), findsWidgets);
  });

  testWidgets('Junior and Senior previews share the same version id',
      (tester) async {
    await _pump(tester, repository: FakeQuestionBankRepository());

    expect(find.text('Junior preview'), findsOneWidget);
    expect(find.text('Senior preview'), findsOneWidget);
    // Slug order picks addition first; both previews must name the same id.
    expect(
      find.textContaining('51000000-0000-0000-0000-000000000002'),
      findsNWidgets(3),
    );
  });

  testWidgets('new question creates a draft', (tester) async {
    final repository = FakeQuestionBankRepository();
    await _pump(tester, repository: repository);

    await tester.tap(find.text('New question'));
    await tester.pumpAndSettle();

    expect(repository.createCount, 1);
    expect(find.textContaining('Which number comes after 4?'), findsWidgets);
  });

  testWidgets('publish turns a draft into published', (tester) async {
    final repository = FakeQuestionBankRepository(seed: [
      const QuestionVersion(
        id: 'draft-1',
        questionId: 'q-draft',
        slug: 'draft-one',
        status: QuestionStatus.draft,
        stem: 'Is this a draft?',
        options: [
          QuestionOption(id: 'yes', label: 'Yes', isCorrect: true),
          QuestionOption(id: 'no', label: 'No'),
        ],
      ),
    ]);
    await _pump(tester, repository: repository);

    expect(find.text('Publish'), findsOneWidget);
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(repository.publishCount, 1);
    expect(find.textContaining('Published'), findsWidgets);
  });

  testWidgets('Urdu shows the Urdu stem in the preview', (tester) async {
    await _pump(
      tester,
      repository: FakeQuestionBankRepository(),
      locale: NanoAppLocale.ur,
    );

    expect(find.textContaining('سیب'), findsWidgets);
  });
}
