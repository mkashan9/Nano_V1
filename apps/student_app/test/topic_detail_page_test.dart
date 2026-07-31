import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/learning/presentation/topic_detail_page.dart';

CatalogTopic _counting({
  TopicProgressStatus status = TopicProgressStatus.notStarted,
  double progress = 0,
  int resumeSeconds = 0,
}) {
  return CatalogTopic(
    topicId: 'topic-counting',
    topicVersionId: 'tv-counting-1',
    slug: 'counting',
    title: 'Counting to 20',
    titleUr: '20 تک گنتی',
    order: 1,
    estimatedMinutes: 12,
    objectives: const ['Count objects to 20', 'Recognise number order'],
    status: status,
    progress: progress,
    resumeSeconds: resumeSeconds,
  );
}

CatalogTopic _addition() {
  return const CatalogTopic(
    topicId: 'topic-addition',
    topicVersionId: 'tv-addition-1',
    slug: 'addition',
    title: 'Adding small numbers',
    order: 2,
    estimatedMinutes: 15,
    objectives: ['Add within 20'],
    blockingTitles: ['Counting to 20'],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required CatalogTopic topic,
  required LearningProgressRepository progress,
  bool junior = true,
  NanoAppLocale locale = NanoAppLocale.en,
  ValueChanged<CatalogTopic>? onOpened,
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
        home: TopicDetailPage(
          topic: topic,
          progressRepository: progress,
          junior: junior,
          onOpened: onOpened,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('unlocked topic starts and the button becomes Resume',
      (tester) async {
    final progress = FakeLearningProgressRepository();
    CatalogTopic? opened;
    await _pump(
      tester,
      topic: _counting(),
      progress: progress,
      onOpened: (topic) => opened = topic,
    );

    expect(find.text('Counting to 20'), findsWidgets);
    expect(find.text("What you'll learn"), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text('Resume'), findsOneWidget);
    expect(progress.started, ['tv-counting-1']);
    expect(opened?.status, TopicProgressStatus.inProgress);
  });

  testWidgets('locked topic shows the unlock reason and disables Start',
      (tester) async {
    await _pump(
      tester,
      topic: _addition(),
      progress: FakeLearningProgressRepository(),
    );

    expect(find.text('How to unlock'), findsOneWidget);
    expect(find.text('Finish Counting to 20 first'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.text('Locked'), findsOneWidget);
  });

  testWidgets('a refused start shows the server message', (tester) async {
    await _pump(
      tester,
      topic: _counting(),
      progress: FakeLearningProgressRepository(alwaysFail: true),
    );

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't start. Try again."), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('Urdu locale renders the locked label', (tester) async {
    await _pump(
      tester,
      topic: _addition(),
      progress: FakeLearningProgressRepository(),
      locale: NanoAppLocale.ur,
    );

    expect(find.text('بند'), findsOneWidget);
    expect(find.textContaining('Counting to 20'), findsOneWidget);
  });
}
