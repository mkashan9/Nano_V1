import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

/// MED-03: what a curator's client and a learner's client each get back.
void main() {
  test('the seeded library is captions with nothing recorded yet', () async {
    // This is the real resting state of a fresh project: lines are authored, and
    // no recording has been approved.
    final repository = FakeNarrationRepository();
    final lines = await repository.published();

    expect(lines, isNotEmpty);
    expect(lines.every((line) => !line.hasAudio), isTrue);
  });

  test('a language nobody has authored is empty, not English', () async {
    final repository = FakeNarrationRepository();

    expect(await repository.published(locale: NanoAppLocale.ur), isEmpty);
  });

  test('surface filters, so a lesson never asks for companion lines', () async {
    final repository = FakeNarrationRepository(
      seed: const [
        NarrationLine(slug: 'idle-1', locale: NanoAppLocale.en, text: 'Wait.'),
        NarrationLine(
          slug: 'intro-1',
          locale: NanoAppLocale.en,
          text: 'Welcome.',
          surface: 'onboarding',
        ),
      ],
    );

    final companion = await repository.published(surface: 'companion');
    expect(companion.map((line) => line.slug), ['idle-1']);
  });

  test('recording a line once is enough', () async {
    final repository = FakeNarrationRepository();

    final first = await repository.request('idle-1');
    expect(first.reused, isFalse);
    expect(first.asset.kind, GeneratedAssetKind.voice);
    expect(first.asset.slot, 'narration_idle-1');

    final again = await repository.request('idle-1');
    expect(again.reused, isTrue);
    expect(repository.requestCount, 2);

    // The line now carries its recording, which is what a learner would fetch.
    final lines = await repository.published();
    expect(lines.firstWhere((line) => line.slug == 'idle-1').hasAudio, isTrue);
  });

  test('a line that can never be recorded is a named answer', () async {
    final repository = FakeNarrationRepository(recordable: false);

    await expectLater(
      repository.request('greeting-1'),
      throwsA(isA<NarrationNotRecordable>()),
    );
  });

  test('an unpublished line cannot be recorded', () async {
    final repository = FakeNarrationRepository();

    await expectLater(
      repository.request('no-such-line'),
      throwsA(isA<StateError>()),
    );
  });

  test('a failing catalog throws so the cache can absorb it', () async {
    // The repository is honest about failure; swallowing it is the cache's job,
    // and only the cache's, so a curator screen can still show a real error.
    final repository = FakeNarrationRepository(alwaysFail: true);

    await expectLater(repository.published(), throwsA(isA<StateError>()));
  });

  test('a signed URL carries its lifetime', () async {
    final repository = FakeNarrationRepository();
    await repository.request('idle-1');
    final line = (await repository.published())
        .firstWhere((line) => line.slug == 'idle-1');

    final url = await repository.signedUrl(
      line.audio!,
      expiresIn: const Duration(minutes: 30),
    );

    expect(url, contains('voice/narration_idle-1/en/hash.wav'));
    expect(url, contains('expires=1800'));
  });
}
