import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

const _stretch = RefreshCheckpoint(
  id: 'cp-660',
  topicVersionId: 'tv-1',
  atSeconds: 660,
  kind: CheckpointKind.stretch,
  prompt: 'Stand up and stretch for a moment.',
  promptUr: 'ایک لمحے کے لیے کھڑے ہوں۔',
);

const _required = RefreshCheckpoint(
  id: 'cp-1320',
  topicVersionId: 'tv-1',
  atSeconds: 1320,
  kind: CheckpointKind.recall,
  prompt: 'Name one thing that keeps an ecosystem in balance.',
  isRequired: true,
);

const _late = RefreshCheckpoint(
  id: 'cp-1800',
  topicVersionId: 'tv-1',
  atSeconds: 1800,
  kind: CheckpointKind.stretch,
  prompt: 'Stand up and stretch for a moment.',
);

const _all = [_stretch, _required, _late];

void main() {
  group('which refresh moment is due', () {
    test('nothing is due before the first checkpoint', () {
      expect(
        CheckpointPolicy.dueAt(
          _all,
          659,
          answeredIds: const {},
          allowOptional: true,
        ),
        isNull,
      );
    });

    test('the checkpoint just crossed is due', () {
      expect(
        CheckpointPolicy.dueAt(
          _all,
          661,
          answeredIds: const {},
          allowOptional: true,
        )?.id,
        'cp-660',
      );
    });

    test('an answered checkpoint does not come back', () {
      expect(
        CheckpointPolicy.dueAt(
          _all,
          665,
          answeredIds: const {'cp-660'},
          allowOptional: true,
        ),
        isNull,
      );
    });

    test('an optional prompt is dropped once the learner has moved on', () {
      expect(
        CheckpointPolicy.dueAt(
          _all,
          660 + CheckpointPolicy.graceSeconds + 1,
          answeredIds: const {},
          allowOptional: true,
        ),
        isNull,
      );
    });

    test('Classroom Mode silences optional prompts but not required ones', () {
      expect(
        CheckpointPolicy.dueAt(
          _all,
          661,
          answeredIds: const {},
          allowOptional: false,
        ),
        isNull,
      );
      expect(
        CheckpointPolicy.dueAt(
          _all,
          1330,
          answeredIds: const {},
          allowOptional: false,
        )?.id,
        'cp-1320',
      );
    });

    test('a required checkpoint still stops a learner who scrubbed past it', () {
      expect(
        CheckpointPolicy.dueAt(
          _all,
          1700,
          answeredIds: const {},
          allowOptional: true,
        )?.id,
        'cp-1320',
      );
    });

    test('the later of two crossed checkpoints wins', () {
      expect(
        CheckpointPolicy.dueAt(
          _all,
          1805,
          answeredIds: const {'cp-1320'},
          allowOptional: true,
        )?.id,
        'cp-1800',
      );
    });
  });

  group('credit gate', () {
    test('stops at the first unanswered required checkpoint', () {
      expect(
        CheckpointPolicy.creditGate(
          _all,
          answeredIds: const {},
          durationSeconds: 2400,
        ),
        1320,
      );
    });

    test('opens to the full duration once it is answered', () {
      expect(
        CheckpointPolicy.creditGate(
          _all,
          answeredIds: const {'cp-1320'},
          durationSeconds: 2400,
        ),
        2400,
      );
    });

    test('optional checkpoints never gate credit', () {
      expect(
        CheckpointPolicy.creditGate(
          const [_stretch, _late],
          answeredIds: const {},
          durationSeconds: 2400,
        ),
        2400,
      );
    });
  });

  group('seeking policy', () {
    test('free content can be scrubbed anywhere', () {
      expect(
        CheckpointPolicy.seekCeiling(
          policy: SeekPolicy.free,
          watchedSeconds: 10,
          durationSeconds: 2400,
        ),
        2400,
      );
    });

    test('no-skip-ahead content stops just past what was watched', () {
      expect(
        CheckpointPolicy.seekCeiling(
          policy: SeekPolicy.noSkipAhead,
          watchedSeconds: 100,
          durationSeconds: 2400,
        ),
        130,
      );
    });

    test('the ceiling never exceeds the video', () {
      expect(
        CheckpointPolicy.seekCeiling(
          policy: SeekPolicy.noSkipAhead,
          watchedSeconds: 2390,
          durationSeconds: 2400,
        ),
        2400,
      );
    });

    test('the wire name maps to the content setting', () {
      expect(SeekPolicy.fromName('no_skip_ahead'), SeekPolicy.noSkipAhead);
      expect(SeekPolicy.fromName('free'), SeekPolicy.free);
      expect(SeekPolicy.fromName(null), SeekPolicy.free);
    });
  });

  group('chapters', () {
    final chapters = VideoChapter.listFrom([
      {'at': 1140, 'title': 'Check yourself', 'protected': true},
      {'at': 0, 'title': 'What an ecosystem is', 'title_ur': 'تعارف'},
      {'at': 660, 'title': 'Food webs'},
    ]);

    test('rows are ordered by position', () {
      expect(
        chapters.map((chapter) => chapter.atSeconds),
        [0, 660, 1140],
      );
    });

    test('a protected chapter is marked', () {
      expect(chapters.last.isProtected, isTrue);
      expect(chapters.first.isProtected, isFalse);
    });

    test('the chapter at a position is the one that started', () {
      expect(
        CheckpointPolicy.chapterAt(chapters, 700)?.title,
        'Food webs',
      );
      expect(CheckpointPolicy.chapterAt(chapters, 0)?.atSeconds, 0);
      expect(CheckpointPolicy.chapterAt(const [], 700), isNull);
    });

    test('Urdu titles are used for Urdu learners when present', () {
      expect(chapters.first.titleFor(NanoAppLocale.ur), 'تعارف');
      expect(chapters[1].titleFor(NanoAppLocale.ur), 'Food webs');
    });
  });

  group('checkpoint rows', () {
    test('a row maps to the model', () {
      final checkpoint = RefreshCheckpoint.fromRow({
        'id': 'cp-1',
        'topic_version_id': 'tv-1',
        'at_seconds': 900,
        'kind': 'recall',
        'prompt': 'What changed?',
        'prompt_ur': 'کیا بدلا؟',
        'is_required': true,
      });
      expect(checkpoint.kind, CheckpointKind.recall);
      expect(checkpoint.isRequired, isTrue);
      expect(checkpoint.promptFor(NanoAppLocale.ur), 'کیا بدلا؟');
      expect(checkpoint.defaultResponse, CheckpointResponse.answered);
    });

    test('an unknown kind falls back to a plain continue prompt', () {
      expect(CheckpointKind.fromName('mystery'), CheckpointKind.ready);
      expect(
        const RefreshCheckpoint(
          id: 'cp-2',
          topicVersionId: 'tv-1',
          atSeconds: 900,
          kind: CheckpointKind.ready,
          prompt: 'Ready?',
        ).defaultResponse,
        CheckpointResponse.continued,
      );
    });

    test('the generator threshold matches the handbook', () {
      expect(CheckpointPolicy.minimumVideoSeconds, 1800);
    });
  });
}
