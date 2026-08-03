import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/learning/presentation/learning_catalog_page.dart';
import 'package:student_app/features/learning/presentation/subject_topics_page.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool junior = true,
  NanoAppLocale locale = NanoAppLocale.en,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    NanoLocaleScope(
      locale: locale,
      copy: NanoCopy(locale),
      child: MaterialApp(
        theme: junior ? NanoTheme.junior() : NanoTheme.senior(),
        home: child,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('junior catalog shows worlds and opens a locked topic list',
      (tester) async {
    final opened = <CatalogTopic>[];
    await _pump(
      tester,
      LearningCatalogPage(
        repository: FakeLearningCatalogRepository(),
        onTopicOpen: opened.add,
      ),
    );
    expect(find.text('Numbers'), findsOneWidget);
    expect(find.text('Science'), findsNothing);

    await tester.tap(find.text('Numbers'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Counting to 20'), findsWidgets);
    expect(find.text('Adding small numbers'), findsOneWidget);
    expect(find.textContaining('Finish Counting to 20 first'), findsOneWidget);

    await tester.tap(find.text('Counting to 20').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(opened.single.topicVersionId, 'tv-counting-1');
  });

  testWidgets('senior catalog search and science eligibility', (tester) async {
    await _pump(
      tester,
      LearningCatalogPage(
        repository: FakeLearningCatalogRepository(seniorEligible: true),
        junior: false,
        useVisualLayout: false,
      ),
      junior: false,
    );
    expect(find.text('Science'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'living');
    await tester.pump();
    expect(find.text('Science'), findsOneWidget);
    expect(find.text('Numbers'), findsNothing);

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();
    expect(find.text('No matches found.'), findsOneWidget);
  });

  testWidgets('subject page unlocks after prerequisite progress', (tester) async {
    await _pump(
      tester,
      SubjectTopicsPage(
        repository: FakeLearningCatalogRepository(countingCompleted: true),
        subjectId: 'subject-math',
      ),
    );
    expect(find.textContaining('Finish'), findsNothing);
    expect(find.text('Start'), findsWidgets);
  });

  testWidgets('load failure shows retry', (tester) async {
    await _pump(
      tester,
      SubjectTopicsPage(
        repository: FakeLearningCatalogRepository(alwaysFail: true),
        subjectId: 'subject-math',
      ),
    );
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('urdu titles appear when locale is ur', (tester) async {
    await _pump(
      tester,
      SubjectTopicsPage(
        repository: FakeLearningCatalogRepository(),
        subjectId: 'subject-math',
      ),
      locale: NanoAppLocale.ur,
    );
    expect(find.text('اعداد'), findsWidgets);
    expect(find.text('20 تک گنتی'), findsWidgets);
  });
}
