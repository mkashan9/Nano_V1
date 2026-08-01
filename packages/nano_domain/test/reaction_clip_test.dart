import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('ReactionClip', () {
    test('fromRow maps the published projection and nothing more', () {
      final clip = ReactionClip.fromRow({
        'slug': 'celebration_celebration',
        'mode': 'celebration',
        'mood': 'celebration',
        'slot': 'celebration_celebration_shortClip',
        'version': 2,
        'aspect_ratio': '9:16',
        'duration_seconds': 4,
        'storage_bucket': 'generated-assets',
        'storage_path': 'video/celebration/en/hash.mp4',
        'content_type': 'video/mp4',
        'byte_size': 1024,
        'checksum': 'sha256:abc',
        // Authoring detail a learner must never receive — and must ignore if
        // something hands it over anyway.
        'direction': 'a warm wave',
        'prompt': 'do not use',
      });

      expect(clip.slug, 'celebration_celebration');
      expect(clip.slot, 'celebration_celebration_shortClip');
      expect(clip.version, 2);
      expect(clip.aspectRatio, '9:16');
      expect(clip.durationSeconds, 4);
      expect(clip.fileKey, 'sha256:abc');
      expect(clip.isPlayable, isTrue);
    });

    test('a clip without a file is not playable', () {
      const clip = ReactionClip(
        slug: 'guide_greeting',
        mode: 'guide',
        mood: 'greeting',
        slot: 'guide_greeting_shortClip',
        version: 1,
        aspectRatio: '1:1',
        storageBucket: '',
        storagePath: '',
      );

      expect(clip.isPlayable, isFalse);
      expect(clip.fileKey, '');
    });

    test('an image content type is not treated as a clip', () {
      const clip = ReactionClip(
        slug: 'celebration_celebration',
        mode: 'celebration',
        mood: 'celebration',
        slot: 'celebration_celebration_shortClip',
        version: 1,
        aspectRatio: '1:1',
        storageBucket: 'generated-assets',
        storagePath: 'image/still.png',
        contentType: 'image/png',
      );

      expect(clip.isPlayable, isFalse);
    });

    test('fileKey falls back to the path when there is no checksum', () {
      const clip = ReactionClip(
        slug: 'quizCoach_celebration',
        mode: 'quizCoach',
        mood: 'celebration',
        slot: 'quizCoach_celebration_shortClip',
        version: 1,
        aspectRatio: '1:1',
        storageBucket: 'generated-assets',
        storagePath: 'video/quiz/en/hash.mp4',
        contentType: 'video/mp4',
      );

      expect(clip.fileKey, 'video/quiz/en/hash.mp4');
      expect(clip.isPlayable, isTrue);
    });
  });

  group('ReactionClipNotAuthorable', () {
    test('names itself so a curator can tell it from a network fault', () {
      const error = ReactionClipNotAuthorable(
        'That reaction is not authored for this shape.',
      );
      expect(error.toString(), contains('ReactionClipNotAuthorable'));
      expect(error.message, contains('shape'));
    });
  });
}
