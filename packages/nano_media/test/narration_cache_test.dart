import 'dart:async';

import 'package:nano_domain/nano_domain.dart';
import 'package:nano_media/nano_media.dart';
import 'package:test/test.dart';

/// MED-03: the narration catalog is fetched rarely, is never allowed to become an
/// error a learner sees, and does not carry one language's recordings into another.
void main() {
  const audio = NarrationAudio(
    storageBucket: 'generated-assets',
    storagePath: 'voice/narration_idle-1/en/hash.wav',
    contentType: 'audio/wav',
    byteSize: 4096,
    checksum: 'sha256:idle',
  );

  NarrationLine line({
    NanoAppLocale locale = NanoAppLocale.en,
    String text = 'Take your time.',
    NarrationAudio? withAudio = audio,
  }) =>
      NarrationLine(
        slug: 'idle-1',
        locale: locale,
        text: text,
        audio: withAudio,
      );

  test('a fresh catalog is not fetched twice', () async {
    var now = DateTime.utc(2026, 8, 1, 9);
    final cache = NarrationCache(
      fetch: (locale) async => [line(locale: locale)],
      clock: () => now,
      ttl: const Duration(hours: 6),
    );

    await cache.load(NanoAppLocale.en);
    await cache.load(NanoAppLocale.en);
    expect(cache.fetchCount, 1);

    now = now.add(const Duration(hours: 7));
    await cache.load(NanoAppLocale.en);
    expect(cache.fetchCount, 2);
  });

  test('screens waking together share one fetch', () async {
    final gate = Completer<void>();
    final cache = NarrationCache(
      fetch: (locale) async {
        await gate.future;
        return [line()];
      },
    );

    final first = cache.load(NanoAppLocale.en);
    final second = cache.load(NanoAppLocale.en);
    gate.complete();
    await Future.wait([first, second]);

    expect(cache.fetchCount, 1);
  });

  test('a failed first fetch is an empty catalog, not an error', () async {
    final cache = NarrationCache(
      fetch: (locale) async => throw StateError('offline'),
    );

    final catalog = await cache.load(NanoAppLocale.en);

    expect(catalog.length, 0);
    expect(cache.hasAudio, isFalse);
    // Kept for diagnostics, never thrown at a screen.
    expect(cache.lastError, isA<StateError>());
  });

  test('a failed first fetch does not lock out a later successful one', () async {
    var fail = true;
    final cache = NarrationCache(
      fetch: (locale) async {
        if (fail) throw StateError('not signed in');
        return [line()];
      },
      ttl: const Duration(hours: 6),
    );

    await cache.load(NanoAppLocale.en);
    expect(cache.current.length, 0);
    expect(cache.isStaleFor(NanoAppLocale.en), isTrue);

    fail = false;
    final catalog = await cache.load(NanoAppLocale.en);
    expect(catalog.length, 1);
    expect(cache.fetchCount, 2);
  });

  test('a later failure keeps the last good catalog', () async {
    var fail = false;
    var now = DateTime.utc(2026, 8, 1, 9);
    final cache = NarrationCache(
      fetch: (locale) async {
        if (fail) throw StateError('offline');
        return [line()];
      },
      clock: () => now,
      ttl: const Duration(hours: 1),
    );

    await cache.load(NanoAppLocale.en);
    fail = true;
    now = now.add(const Duration(hours: 2));
    final catalog = await cache.load(NanoAppLocale.en);

    expect(catalog.length, 1);
    expect(catalog.lookup('idle-1')?.text, 'Take your time.');
  });

  test('switching language drops the old recordings and fetches again', () async {
    final requested = <NanoAppLocale>[];
    final cache = NarrationCache(
      fetch: (locale) async {
        requested.add(locale);
        return [
          line(
            locale: locale,
            text: locale == NanoAppLocale.ur ? 'آرام سے کریں۔' : 'Take your time.',
          ),
        ];
      },
      sign: (_, _) async => 'https://signed.local/audio',
    );

    await cache.load(NanoAppLocale.en);
    await cache.urlFor(audio);
    expect(cache.signedUrlCount, 1);

    await cache.load(NanoAppLocale.ur);

    expect(requested, [NanoAppLocale.en, NanoAppLocale.ur]);
    expect(cache.current.locale, NanoAppLocale.ur);
    expect(cache.current.lookup('idle-1')?.text, 'آرام سے کریں۔');
    // The English URL is dropped rather than reused: it points at English speech,
    // and this learner is now reading Urdu.
    expect(cache.signedUrlCount, 0);
  });

  test('a language switch that fails leaves nothing from the old language',
      () async {
    var fail = false;
    final cache = NarrationCache(
      fetch: (locale) async {
        if (fail) throw StateError('offline');
        return [line(locale: locale)];
      },
    );

    await cache.load(NanoAppLocale.en);
    fail = true;
    final catalog = await cache.load(NanoAppLocale.ur);

    // Empty is correct here. Keeping the English lines would have shown English
    // captions to an Urdu reader.
    expect(catalog.length, 0);
  });

  test('a signed URL is reused until it is nearly expired', () async {
    var signCount = 0;
    var now = DateTime.utc(2026, 8, 1, 9);
    final cache = NarrationCache(
      fetch: (locale) async => [line()],
      sign: (_, _) async {
        signCount++;
        return 'https://signed.local/$signCount';
      },
      clock: () => now,
      signedUrlLifetime: const Duration(minutes: 30),
      signedUrlSafetyMargin: const Duration(minutes: 2),
    );

    await cache.load(NanoAppLocale.en);
    expect(await cache.urlFor(audio), 'https://signed.local/1');
    now = now.add(const Duration(minutes: 20));
    expect(await cache.urlFor(audio), 'https://signed.local/1');
    // Past the safety margin: a URL handed to a player must still be valid when
    // the player gets to it.
    now = now.add(const Duration(minutes: 9));
    expect(await cache.urlFor(audio), 'https://signed.local/2');
    expect(signCount, 2);
  });

  test('a re-recorded line gets a new URL', () async {
    final cache = NarrationCache(
      fetch: (locale) async => [line()],
      sign: (audio, _) async => 'https://signed.local/${audio.checksum}',
    );

    await cache.load(NanoAppLocale.en);
    expect(await cache.urlFor(audio), 'https://signed.local/sha256:idle');

    const rerecorded = NarrationAudio(
      storageBucket: 'generated-assets',
      storagePath: 'voice/narration_idle-1/en/hash.wav',
      contentType: 'audio/wav',
      byteSize: 4096,
      checksum: 'sha256:idle-v2',
    );
    expect(await cache.urlFor(rerecorded), 'https://signed.local/sha256:idle-v2');
  });

  test('no signer, or a failing one, means no URL rather than an error', () async {
    final unsignable = NarrationCache(fetch: (locale) async => [line()]);
    await unsignable.load(NanoAppLocale.en);
    expect(await unsignable.urlFor(audio), isNull);

    final failing = NarrationCache(
      fetch: (locale) async => [line()],
      sign: (_, _) async => throw StateError('signing unavailable'),
    );
    await failing.load(NanoAppLocale.en);
    expect(await failing.urlFor(audio), isNull);
    expect(failing.lastError, isA<StateError>());
  });

  test('clearing leaves nothing for the next person on the device', () async {
    final cache = NarrationCache(
      fetch: (locale) async => [line()],
      sign: (_, _) async => 'https://signed.local/audio',
    );

    await cache.load(NanoAppLocale.en);
    await cache.urlFor(audio);
    cache.clear();

    expect(cache.current.length, 0);
    expect(cache.signedUrlCount, 0);
    expect(cache.isStaleFor(NanoAppLocale.en), isTrue);
  });
}
