import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('FakeReactionClipRepository', () {
    test('starts empty, which is the resting state until a curator approves',
        () async {
      final repository = FakeReactionClipRepository();

      expect(await repository.published(), isEmpty);
    });

    test('a seeded celebration clip is what the local manifest already reaches',
        () async {
      final repository = FakeReactionClipRepository(
        seed: [FakeReactionClipRepository.celebrationSeed],
      );

      final published = await repository.published();

      expect(published, hasLength(1));
      expect(published.single.slug, 'celebration_celebration');
      expect(published.single.slot, 'celebration_celebration_shortClip');
      expect(published.single.isPlayable, isTrue);
    });

    test('requesting a new slug publishes a playable clip', () async {
      final repository = FakeReactionClipRepository();

      final outcome = await repository.request('guide_greeting');

      expect(outcome.reused, isFalse);
      expect(outcome.asset.kind, GeneratedAssetKind.video);
      expect(outcome.asset.slot, 'guide_greeting_shortClip');
      expect(outcome.asset.providerId, isNull);
      expect(await repository.published(), hasLength(1));
      expect(repository.requestCount, 1);
    });

    test('asking for the same reaction and shape reuses the existing clip',
        () async {
      final repository = FakeReactionClipRepository();
      await repository.request('celebration_celebration');

      final second = await repository.request('celebration_celebration');

      expect(second.reused, isTrue);
      expect(await repository.published(), hasLength(1));
    });

    test('a different shape is a different clip', () async {
      final repository = FakeReactionClipRepository();
      await repository.request('celebration_celebration');
      await repository.request(
        'celebration_celebration',
        aspectRatio: '9:16',
      );

      expect(await repository.published(), hasLength(2));
    });

    test('an unauthorable ask is refused by name, not as a network fault',
        () async {
      final repository = FakeReactionClipRepository(authorable: false);

      expect(
        repository.request('celebration_celebration'),
        throwsA(isA<ReactionClipNotAuthorable>()),
      );
    });

    test('a malformed slug is refused rather than filmed', () async {
      final repository = FakeReactionClipRepository();

      expect(
        repository.request('not-a-reaction'),
        throwsA(isA<ReactionClipNotAuthorable>()),
      );
    });

    test('a signed URL is per clip and time limited', () async {
      final repository = FakeReactionClipRepository(
        seed: [FakeReactionClipRepository.celebrationSeed],
      );
      final clip = (await repository.published()).single;

      final url = await repository.signedUrl(
        clip,
        expiresIn: const Duration(minutes: 5),
      );

      expect(url, contains(clip.storagePath));
      expect(url, contains('expires=300'));
    });

    test('failures surface as errors rather than empty lists', () async {
      final repository = FakeReactionClipRepository(alwaysFail: true);

      expect(repository.published(), throwsStateError);
    });
  });

  group('FakeGeneratedAssetRepository video provider', () {
    test('a new video ask names the Veo provider', () async {
      final repository = FakeGeneratedAssetRepository(seed: const []);

      final outcome = await repository.request(
        const GeneratedAssetRequest(
          kind: GeneratedAssetKind.video,
          slot: 'celebration_celebration_shortClip',
          prompt: 'a short celebration',
          promptVersion: 'v1',
        ),
      );

      expect(outcome.asset.providerId, 'wan_i2v_space');
    });
  });
}
