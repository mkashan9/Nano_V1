import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/learning/presentation/learning_progress_page.dart';

Future<void> _pump(
  WidgetTester tester, {
  required LearningInsightsRepository repository,
  bool junior = true,
  NanoAppLocale locale = NanoAppLocale.en,
  ValueChanged<NextUpSuggestion>? onOpenSuggestion,
}) async {
  // Tall surface so the whole page is laid out; the list scrolls on a phone.
  await tester.binding.setSurfaceSize(const Size(900, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    NanoLocaleScope(
      locale: locale,
      copy: NanoCopy(locale),
      child: MaterialApp(
        home: LearningProgressPage(
          repository: repository,
          junior: junior,
          onOpenSuggestion: onOpenSuggestion,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the recommendation leads with why it is being suggested',
      (tester) async {
    await _pump(tester, repository: FakeLearningInsightsRepository());

    expect(find.text('Up next'), findsOneWidget);
    expect(find.text('Adding small numbers'), findsOneWidget);
    expect(find.text('You left this unfinished'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Resume'), findsOneWidget);
  });

  testWidgets('alternatives appear below the recommendation', (tester) async {
    await _pump(tester, repository: FakeLearningInsightsRepository());

    expect(find.text('Living things'), findsOneWidget);
    expect(find.text('Next in this subject'), findsOneWidget);
    // Only the recommendation gets an action button.
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('tapping the recommendation hands back the suggestion',
      (tester) async {
    NextUpSuggestion? opened;
    await _pump(
      tester,
      repository: FakeLearningInsightsRepository(),
      onOpenSuggestion: (suggestion) => opened = suggestion,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Resume'));
    await tester.pump();

    expect(opened?.topicVersionId, 'tv-addition-1');
  });

  testWidgets('progress is stated in words, not only as a bar', (tester) async {
    await _pump(tester, repository: FakeLearningInsightsRepository());

    expect(find.text('1 of 5 done'), findsOneWidget);
    expect(find.text('3 minutes watched'), findsOneWidget);
    expect(find.text('1 of 2 done'), findsOneWidget);
    expect(find.text('0 of 3 done'), findsOneWidget);
    expect(find.text('1 still locked'), findsOneWidget);
  });

  testWidgets('the strong subject and the one worth time are both named',
      (tester) async {
    await _pump(tester, repository: FakeLearningInsightsRepository());

    expect(find.text('Going well: Math'), findsOneWidget);
    expect(find.text('Worth some time: Science'), findsOneWidget);
  });

  testWidgets('a learner who has started nothing is told so', (tester) async {
    await _pump(
      tester,
      repository: FakeLearningInsightsRepository(mathStarted: false),
    );

    expect(find.text('Nothing started yet.'), findsOneWidget);
    expect(find.textContaining('Going well'), findsNothing);
  });

  testWidgets('finishing everything is celebrated, not left blank',
      (tester) async {
    await _pump(
      tester,
      repository: FakeLearningInsightsRepository(allFinished: true),
    );

    expect(find.text('Everything is finished. Well done.'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('no learning at all shows the empty state', (tester) async {
    await _pump(
      tester,
      repository: FakeLearningInsightsRepository(empty: true),
    );

    expect(find.text('No learning yet'), findsOneWidget);
  });

  testWidgets('a failed load offers a retry that works', (tester) async {
    final repository = FakeLearningInsightsRepository(alwaysFail: true);
    await _pump(tester, repository: repository);

    expect(repository.loadCount, 1);
    final retry = find.widgetWithText(FilledButton, 'Try again');
    expect(retry, findsOneWidget);

    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(repository.loadCount, 2);
  });

  testWidgets('Urdu reads the reason and the subject in Urdu', (tester) async {
    await _pump(
      tester,
      repository: FakeLearningInsightsRepository(),
      locale: NanoAppLocale.ur,
      junior: false,
    );

    expect(find.text('چھوٹے اعداد جمع'), findsOneWidget);
    expect(find.text('یہ ادھورا رہ گیا تھا'), findsOneWidget);
    expect(find.text('حساب'), findsWidgets);
  });

  testWidgets('progress bars carry a spoken value for screen readers',
      (tester) async {
    await _pump(tester, repository: FakeLearningInsightsRepository());

    final handle = tester.ensureSemantics();
    final semantics = tester.getSemantics(
      find.byType(LinearProgressIndicator).last,
    );
    expect(semantics.value, isNotEmpty);
    handle.dispose();
  });
}
