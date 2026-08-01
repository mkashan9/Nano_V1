import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

/// MED-03: what a client makes of a narration row, including the ordinary case
/// where nobody has recorded anything.
void main() {
  group('NarrationLine.fromRow', () {
    test('reads wording and audio identity', () {
      final line = NarrationLine.fromRow({
        'slug': 'idle-1',
        'surface': 'companion',
        'version': 2,
        'locale': 'ur',
        'line_text': 'آرام سے کریں۔',
        'voice_id': 'aoede',
        'storage_bucket': 'generated-assets',
        'storage_path': 'voice/narration_idle-1/ur/hash.wav',
        'content_type': 'audio/wav',
        'byte_size': 4096,
        'checksum': 'sha256:idle',
      });

      expect(line.slug, 'idle-1');
      expect(line.locale, NanoAppLocale.ur);
      expect(line.version, 2);
      expect(line.text, 'آرام سے کریں۔');
      expect(line.hasAudio, isTrue);
      expect(line.audio!.voiceId, 'aoede');
      // Keyed by content: a re-recording under the same path still gets a fresh
      // URL, because the checksum moved.
      expect(line.audio!.fileKey, 'sha256:idle');
    });

    test('a line with no recording is a line, not a failure', () {
      final line = NarrationLine.fromRow({
        'slug': 'celebration-1',
        'version': 1,
        'locale': 'en',
        'line_text': 'Nicely done!',
        'storage_path': null,
      });

      expect(line.hasAudio, isFalse);
      expect(line.text, 'Nicely done!');
    });

    test('an empty path is treated as no recording', () {
      final line = NarrationLine.fromRow({
        'slug': 'idle-1',
        'locale': 'en',
        'line_text': 'Take your time.',
        'storage_path': '',
      });

      expect(line.hasAudio, isFalse);
    });

    test('without a checksum the path identifies the file', () {
      final line = NarrationLine.fromRow({
        'slug': 'idle-1',
        'locale': 'en',
        'line_text': 'Take your time.',
        'storage_path': 'voice/narration_idle-1/en/hash.wav',
      });

      expect(line.audio!.fileKey, 'voice/narration_idle-1/en/hash.wav');
    });
  });

  test('a line that can never be recorded says why', () {
    const error = NarrationNotRecordable(
      'A line with a placeholder cannot be pre-recorded.',
    );
    expect(error.toString(), contains('placeholder'));
  });
}
