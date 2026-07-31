import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/learning/presentation/topic_player_page.dart';

const _counting = CatalogTopic(
  topicId: 'topic-counting',
  topicVersionId: 'tv-counting-1',
  slug: 'counting',
  title: 'Counting to 20',
  titleUr: '20 تک گنتی',
  order: 1,
  estimatedMinutes: 12,
  durationSeconds: 120,
  completionThreshold: 0.9,
  videoProvider: 'fixture',
  videoRef: 'counting-to-20',
  captions: CaptionTrack([
    CaptionCue(
      atSeconds: 0,
      text: 'Let us count to twenty.',
      textUr: 'آئیے بیس تک گنتی کریں۔',
    ),
    CaptionCue(atSeconds: 30, text: 'Ten comes after nine.'),
  ]),
);

Future<void> _pump(
  WidgetTester tester, {
  CatalogTopic topic = _counting,
  required LearningProgressRepository progress,
  NanoAppLocale locale = NanoAppLocale.en,
  AccessibilityPreferences? accessibility,
  ValueChanged<CatalogTopic>? onProgress,
}) async {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final prefs = accessibility ?? AccessibilityPreferences.defaults;
  await tester.pumpWidget(
    NanoLocaleScope(
      locale: locale,
      copy: NanoCopy(locale),
      child: NanoAccessibilityScope(
        preferences: prefs,
        feedback: NanoFeedback(preferences: prefs),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: TopicPlayerPage(
            topic: topic,
            progressRepository: progress,
            tick: const Duration(milliseconds: 1),
            onProgress: onProgress,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the player resumes where the learner stopped', (tester) async {
    await _pump(
      tester,
      topic: _counting.copyWith(
        status: TopicProgressStatus.inProgress,
        resumeSeconds: 45,
        watchedSeconds: 45,
        progress: 0.375,
      ),
      progress: FakeLearningProgressRepository(),
    );

    expect(find.text('0:45 / 2:00'), findsOneWidget);
    expect(find.text('Watched: 0:45'), findsOneWidget);
  });

  testWidgets('watching advances the clock and reports to the server',
      (tester) async {
    final repo = FakeLearningProgressRepository();
    await repo.start('tv-counting-1');
    await _pump(tester, progress: repo);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    // Fifteen one-second ticks reach the first heartbeat.
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    // Pause stops the clock; pumpAndSettle would otherwise run the whole video.
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pumpAndSettle();

    expect(repo.positions.first, 15);
    expect(find.text('Watched: 0:15'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('dragging to the end does not unlock completion', (tester) async {
    final repo = FakeLearningProgressRepository();
    await repo.start('tv-counting-1');
    await _pump(tester, progress: repo);

    await tester.drag(find.byType(Slider), const Offset(600, 0));
    await tester.pumpAndSettle();

    expect(find.text('2:00 / 2:00'), findsOneWidget);
    // The jump reports position 120 but only earns one beat of wall clock,
    // so most of the video is still owed.
    expect(find.text('Watch 90 more seconds to finish'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
      reason: 'seeking must not earn credit',
    );
  });

  testWidgets('completion is offered once the server credits enough time',
      (tester) async {
    final repo = FakeLearningProgressRepository();
    await repo.start('tv-counting-1');
    CatalogTopic? reported;
    await _pump(
      tester,
      topic: _counting.copyWith(
        status: TopicProgressStatus.inProgress,
        resumeSeconds: 110,
        watchedSeconds: 110,
        progress: 0.92,
      ),
      progress: repo,
      onProgress: (topic) => reported = topic,
    );
    repo.seedWatched('tv-counting-1', 110);

    expect(find.text('Watch 108 more seconds to finish'), findsNothing);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsOneWidget);
    expect(repo.completed, ['tv-counting-1']);
    expect(reported?.isCompleted, isTrue);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
      reason: 'a finished topic cannot be completed twice',
    );
  });

  testWidgets('a refused completion explains what is left', (tester) async {
    final repo = FakeLearningProgressRepository();
    await repo.start('tv-counting-1');
    repo.seedWatched('tv-counting-1', 20);
    await _pump(
      tester,
      // The client thinks it is ready; the server disagrees.
      topic: _counting.copyWith(watchedSeconds: 120, progress: 1),
      progress: repo,
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('Keep watching'), findsOneWidget);
    expect(find.text('Completed'), findsNothing);
  });

  testWidgets('captions follow the learner preference and the position',
      (tester) async {
    await _pump(
      tester,
      progress: FakeLearningProgressRepository(),
      accessibility:
          AccessibilityPreferences.defaults.copyWith(captionsEnabled: false),
    );

    expect(find.text('Let us count to twenty.'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Let us count to twenty.'), findsOneWidget);
  });

  testWidgets('Urdu captions render for Urdu learners', (tester) async {
    await _pump(
      tester,
      progress: FakeLearningProgressRepository(),
      locale: NanoAppLocale.ur,
    );

    expect(find.text('آئیے بیس تک گنتی کریں۔'), findsOneWidget);
  });

  testWidgets('a topic without a video says so instead of pretending',
      (tester) async {
    await _pump(
      tester,
      topic: const CatalogTopic(
        topicId: 'topic-loops',
        topicVersionId: 'tv-first-loop-1',
        slug: 'first-loop',
        title: 'Your first loop',
        order: 1,
        estimatedMinutes: 20,
        durationSeconds: 300,
      ),
      progress: FakeLearningProgressRepository(),
    );

    expect(find.text('The video is not available yet.'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
  });
}
