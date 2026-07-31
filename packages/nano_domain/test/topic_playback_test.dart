import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('PlaybackPolicy credit', () {
    test('a heartbeat never earns more than the clock allows', () {
      // Jumped two minutes ahead in fifteen seconds of real time.
      expect(
        PlaybackPolicy.creditFor(positionDelta: 120, elapsedSeconds: 15),
        18,
      );
    });

    test('watching normally earns the time watched', () {
      expect(
        PlaybackPolicy.creditFor(positionDelta: 15, elapsedSeconds: 15),
        15,
      );
    });

    test('seeking backwards earns nothing', () {
      expect(
        PlaybackPolicy.creditFor(positionDelta: -40, elapsedSeconds: 15),
        0,
      );
    });

    test('a single beat is capped even after a long gap', () {
      expect(
        PlaybackPolicy.creditFor(positionDelta: 4000, elapsedSeconds: 4000),
        PlaybackPolicy.maxCreditPerBeat,
      );
    });
  });

  group('PlaybackPolicy completion', () {
    test('threshold is measured against credited seconds', () {
      expect(
        PlaybackPolicy.requiredSeconds(durationSeconds: 120, threshold: 0.9),
        108,
      );
      expect(
        PlaybackPolicy.canComplete(
          watchedSeconds: 107,
          durationSeconds: 120,
          threshold: 0.9,
        ),
        isFalse,
      );
      expect(
        PlaybackPolicy.canComplete(
          watchedSeconds: 108,
          durationSeconds: 120,
          threshold: 0.9,
        ),
        isTrue,
      );
    });

    test('remaining time never goes negative', () {
      expect(
        PlaybackPolicy.remainingSeconds(
          watchedSeconds: 200,
          durationSeconds: 120,
          threshold: 0.9,
        ),
        0,
      );
    });
  });

  group('resume', () {
    test('picks up where the learner stopped', () {
      expect(
        PlaybackPolicy.resumeFrom(
          resumeSeconds: 45,
          durationSeconds: 120,
          isCompleted: false,
        ),
        45,
      );
    });

    test('a finished topic replays from the start', () {
      expect(
        PlaybackPolicy.resumeFrom(
          resumeSeconds: 118,
          durationSeconds: 120,
          isCompleted: true,
        ),
        0,
      );
    });

    test('a position at the end restarts rather than sitting on the last frame',
        () {
      expect(
        PlaybackPolicy.resumeFrom(
          resumeSeconds: 120,
          durationSeconds: 120,
          isCompleted: false,
        ),
        0,
      );
    });
  });

  group('captions', () {
    final track = CaptionTrack.fromRows([
      {'at': 30, 'text': 'Ten comes after nine.', 'text_ur': 'دس'},
      {'at': 0, 'text': 'Let us count.', 'text_ur': 'گنتی'},
    ]);

    test('rows are sorted by time', () {
      expect(track.cues.map((c) => c.atSeconds), [0, 30]);
    });

    test('the cue covering a position wins', () {
      expect(track.cueAt(0)?.text, 'Let us count.');
      expect(track.cueAt(29)?.text, 'Let us count.');
      expect(track.cueAt(31)?.text, 'Ten comes after nine.');
    });

    test('Urdu falls back to English when no translation exists', () {
      const cue = CaptionCue(atSeconds: 0, text: 'Only English');
      expect(cue.textFor(NanoAppLocale.ur), 'Only English');
    });

    test('a malformed track is empty rather than throwing', () {
      expect(CaptionTrack.fromRows('nope').isEmpty, isTrue);
    });
  });

  group('CatalogTopic playback fields', () {
    test('completion readiness comes from credited seconds, not position', () {
      const topic = CatalogTopic(
        topicId: 't',
        topicVersionId: 'tv',
        slug: 'counting',
        title: 'Counting to 20',
        order: 1,
        estimatedMinutes: 12,
        durationSeconds: 120,
        completionThreshold: 0.9,
        resumeSeconds: 120,
        watchedSeconds: 10,
        videoRef: 'counting-to-20',
      );

      expect(topic.hasVideo, isTrue);
      expect(topic.meetsCompletionThreshold, isFalse);
      expect(topic.secondsLeftToComplete, 98);
    });

    test('applying a server row carries credited seconds forward', () {
      const topic = CatalogTopic(
        topicId: 't',
        topicVersionId: 'tv',
        slug: 'counting',
        title: 'Counting to 20',
        order: 1,
        estimatedMinutes: 12,
        durationSeconds: 120,
      );

      final updated = TopicActionPolicy.applyProgress(
        topic,
        const TopicProgress(
          userId: 'u1',
          topicVersionId: 'tv',
          status: TopicProgressStatus.inProgress,
          progress: 0.9,
          resumeSeconds: 110,
          watchedSeconds: 108,
        ),
      );

      expect(updated.watchedSeconds, 108);
      expect(updated.meetsCompletionThreshold, isTrue);
    });
  });

  test('clock formats mm:ss', () {
    expect(PlaybackPolicy.clock(0), '0:00');
    expect(PlaybackPolicy.clock(75), '1:15');
    expect(PlaybackPolicy.clock(-5), '0:00');
  });
}
