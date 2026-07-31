import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/learning/presentation/topic_player_page.dart';

/// A short stand-in for the forty-minute fixture: same checkpoint layout,
/// scaled down so a widget test can walk the play head across it.
const _ecosystems = CatalogTopic(
  topicId: 'topic-ecosystems',
  topicVersionId: 'tv-ecosystems-1',
  slug: 'ecosystems-in-depth',
  title: 'Ecosystems in depth',
  order: 3,
  estimatedMinutes: 40,
  durationSeconds: 120,
  completionThreshold: 0.9,
  videoProvider: 'fixture',
  videoRef: 'ecosystems-in-depth',
  chapters: [
    VideoChapter(atSeconds: 0, title: 'What an ecosystem is'),
    VideoChapter(atSeconds: 30, title: 'Food webs'),
    VideoChapter(atSeconds: 55, title: 'Check yourself', isProtected: true),
    VideoChapter(atSeconds: 70, title: 'When balance fails'),
  ],
);

const _optional = RefreshCheckpoint(
  id: 'cp-30',
  topicVersionId: 'tv-ecosystems-1',
  atSeconds: 30,
  kind: CheckpointKind.stretch,
  prompt: 'Stand up and stretch for a moment.',
  promptUr: 'ایک لمحے کے لیے کھڑے ہوں۔',
);

const _required = RefreshCheckpoint(
  id: 'cp-70',
  topicVersionId: 'tv-ecosystems-1',
  atSeconds: 70,
  kind: CheckpointKind.recall,
  prompt: 'Name one thing that keeps an ecosystem in balance.',
  isRequired: true,
);

Future<void> _pump(
  WidgetTester tester, {
  CatalogTopic topic = _ecosystems,
  required LearningProgressRepository progress,
  CheckpointRepository? checkpoints,
  NanoAppLocale locale = NanoAppLocale.en,
  AccessibilityPreferences? accessibility,
}) async {
  tester.view.physicalSize = const Size(900, 2800);
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
            checkpointRepository: checkpoints,
            junior: false,
            captionsEnabled: false,
            tick: const Duration(milliseconds: 1),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Plays [seconds] of video one tick at a time, leaving the clock running.
Future<void> _watch(WidgetTester tester, int seconds) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
}

void main() {
  testWidgets('a refresh moment pauses playback and asks to continue',
      (tester) async {
    final checkpoints = FakeCheckpointRepository(
      checkpoints: const [_optional, _required],
    );
    await _pump(
      tester,
      progress: FakeLearningProgressRepository(),
      checkpoints: checkpoints,
    );

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await _watch(tester, 31);
    await tester.pump();

    expect(find.text('Quick break'), findsOneWidget);
    expect(find.text('Stand up and stretch for a moment.'), findsOneWidget);
    // Paused, so the play icon is back.
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    await tester.tap(find.text('Keep watching'));
    await tester.pumpAndSettle(const Duration(milliseconds: 1));

    expect(find.text('Quick break'), findsNothing);
    expect(
      checkpoints.responses.single,
      CheckpointResponse.stretched,
    );
  });

  testWidgets('an answered refresh moment does not come back', (tester) async {
    final checkpoints = FakeCheckpointRepository(
      checkpoints: const [_optional, _required],
    );
    await _pump(
      tester,
      progress: FakeLearningProgressRepository(),
      checkpoints: checkpoints,
    );

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await _watch(tester, 31);
    await tester.pump();
    await tester.tap(find.text('Keep watching'));
    await tester.pump();
    await _watch(tester, 20);
    await tester.pump();

    expect(find.text('Quick break'), findsNothing);
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
  });

  testWidgets('taking a break leaves the video paused', (tester) async {
    final checkpoints = FakeCheckpointRepository(
      checkpoints: const [_optional, _required],
    );
    await _pump(
      tester,
      progress: FakeLearningProgressRepository(),
      checkpoints: checkpoints,
    );

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await _watch(tester, 31);
    await tester.pump();
    await tester.tap(find.text('Take a break'));
    await tester.pump();

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(checkpoints.responses.single, CheckpointResponse.postponed);
  });

  testWidgets('Classroom Mode silences the optional prompt but not the required one',
      (tester) async {
    final checkpoints = FakeCheckpointRepository(
      checkpoints: const [_optional, _required],
    );
    await _pump(
      tester,
      progress: FakeLearningProgressRepository(),
      checkpoints: checkpoints,
      accessibility: const AccessibilityPreferences(classroomMode: true),
    );

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await _watch(tester, 35);
    await tester.pump();

    expect(find.text('Quick break'), findsNothing);

    await _watch(tester, 40);
    await tester.pump();

    expect(find.text('Think back'), findsOneWidget);
    expect(
      find.text('Progress is paused here until you answer.'),
      findsWidgets,
    );
  });

  testWidgets('a required moment says credit is paused until it is answered',
      (tester) async {
    final progress = FakeLearningProgressRepository(
      durations: {'tv-ecosystems-1': 120},
      creditGates: {'tv-ecosystems-1': 70},
    );
    final checkpoints = FakeCheckpointRepository(
      checkpoints: const [_required],
    );
    await _pump(
      tester,
      progress: progress,
      checkpoints: checkpoints,
    );

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await _watch(tester, 71);
    await tester.pump();

    expect(find.text('Think back'), findsOneWidget);
    expect(
      find.text('Name one thing that keeps an ecosystem in balance.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Keep watching'));
    await tester.pumpAndSettle(const Duration(milliseconds: 1));

    expect(checkpoints.answered, {'cp-70'});
    expect(checkpoints.responses.single, CheckpointResponse.answered);
  });

  testWidgets('the current chapter is named', (tester) async {
    await _pump(
      tester,
      topic: _ecosystems.copyWith(resumeSeconds: 40, watchedSeconds: 40),
      progress: FakeLearningProgressRepository(
        durations: {'tv-ecosystems-1': 120},
      ),
    );

    expect(find.text('Food webs'), findsOneWidget);
  });

  testWidgets('no-skip-ahead content refuses to scrub past what was watched',
      (tester) async {
    final progress = FakeLearningProgressRepository(
      durations: {'tv-ecosystems-1': 120},
    );
    await _pump(
      tester,
      topic: _ecosystems.copyWith(
        seekPolicy: SeekPolicy.noSkipAhead,
        status: TopicProgressStatus.inProgress,
        resumeSeconds: 10,
        watchedSeconds: 10,
      ),
      progress: progress,
    );

    expect(find.text("You can't skip ahead in this video."), findsOneWidget);

    await tester.drag(find.byType(Slider), const Offset(600, 0));
    await tester.pump();

    // The head stops at the watched ceiling, and that is what is reported.
    expect(find.text('0:40 / 2:00'), findsOneWidget);
    expect(progress.positions.last, 40);
  });
}
