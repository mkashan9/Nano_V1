import 'package:nano_domain/nano_domain.dart';
import 'package:nano_media/nano_media.dart';
import 'package:test/test.dart';

/// MED-03: when the Learning Guide may be heard, and the many ordinary reasons it
/// may not. Every case still puts the same words on screen.
void main() {
  const audio = NarrationAudio(
    storageBucket: 'generated-assets',
    storagePath: 'voice/narration_celebration-1/en/hash.wav',
    contentType: 'audio/wav',
    byteSize: 4096,
    checksum: 'sha256:celebration',
    voiceId: 'aoede',
  );

  NarrationLine line({
    String slug = 'celebration-1',
    String text = 'Nicely done!',
    NanoAppLocale locale = NanoAppLocale.en,
    NarrationAudio? withAudio = audio,
  }) =>
      NarrationLine(
        slug: slug,
        locale: locale,
        text: text,
        audio: withAudio,
      );

  /// A reaction the way the runtime builds one, so the script id and caption used
  /// here are the ones a real screen would show.
  CompanionReaction reactionFor(
    CompanionEvent event, {
    bool soundEnabled = true,
    String companionName = 'Nori',
  }) {
    final runtime = CompanionRuntime.forExperience(
      junior: true,
      preferences: AccessibilityPreferences.defaults
          .copyWith(soundEnabled: soundEnabled),
      companionName: companionName,
    ).notify(event, now: DateTime.utc(2026, 8, 1));
    return runtime.reaction!;
  }

  test('a recording of these exact words in this language can be heard', () {
    final catalog = NarrationCatalog.fromLines(
      [line()],
      locale: NanoAppLocale.en,
    );
    final choice = catalog.choose(reactionFor(CompanionEvent.quizComplete));

    expect(choice.caption, 'Nicely done!');
    expect(choice.canSpeak, isTrue);
    expect(choice.audio, audio);
    expect(choice.fallback, NarrationFallback.none);
  });

  test('an unauthored line is read, not heard', () {
    final choice = NarrationCatalog.empty
        .choose(reactionFor(CompanionEvent.quizComplete));

    expect(choice.caption, isNotEmpty);
    expect(choice.canSpeak, isFalse);
    expect(choice.fallback, NarrationFallback.noLine);
  });

  test('an authored line nobody has recorded is read', () {
    final catalog = NarrationCatalog.fromLines(
      [line(withAudio: null)],
      locale: NanoAppLocale.en,
    );
    final choice = catalog.choose(reactionFor(CompanionEvent.quizComplete));

    expect(choice.canSpeak, isFalse);
    expect(choice.fallback, NarrationFallback.noRecording);
  });

  test('a recording of older wording is never played under a new caption', () {
    final catalog = NarrationCatalog.fromLines(
      [line(text: 'Some completely different sentence.')],
      locale: NanoAppLocale.en,
    );
    final choice = catalog.choose(reactionFor(CompanionEvent.quizComplete));

    // The recording exists and is approved. It just says something else.
    expect(choice.canSpeak, isFalse);
    expect(choice.fallback, NarrationFallback.wordingChanged);
    expect(choice.caption, 'Nicely done!');
  });

  test('punctuation and spacing are not a mismatch', () {
    final catalog = NarrationCatalog.fromLines(
      [line(text: '  nicely   DONE! ')],
      locale: NanoAppLocale.en,
    );
    expect(
      catalog.choose(reactionFor(CompanionEvent.quizComplete)).canSpeak,
      isTrue,
    );
  });

  test('a line naming the learner-chosen companion is never recorded', () {
    // greeting-1 contains {name}. Even with a recording present it must not play:
    // the audio would greet somebody else's companion.
    final catalog = NarrationCatalog.fromLines(
      [
        line(
          slug: 'greeting-1',
          text: 'Hello! Nori is here whenever you are ready.',
        ),
      ],
      locale: NanoAppLocale.en,
    );
    final reaction = reactionFor(CompanionEvent.appOpen, companionName: 'Tara');
    final choice = catalog.choose(reaction);

    expect(reaction.script.id, 'greeting-1');
    expect(choice.caption, contains('Tara'));
    expect(choice.canSpeak, isFalse);
    expect(choice.fallback, NarrationFallback.personalised);
  });

  test('sound off keeps every word and plays none of them', () {
    final catalog = NarrationCatalog.fromLines(
      [line()],
      locale: NanoAppLocale.en,
    );
    // No argument about sound: the reaction already knows, which is what stops a
    // caller from accidentally speaking over a muted learner.
    final choice = catalog.choose(
      reactionFor(CompanionEvent.quizComplete, soundEnabled: false),
    );

    expect(choice.caption, 'Nicely done!');
    expect(choice.canSpeak, isFalse);
    expect(choice.fallback, NarrationFallback.soundOff);
  });

  test('a catalog holds one language and never substitutes another', () {
    // Unlike silent art, speech does not travel: an English recording under an
    // Urdu caption would be worse than silence.
    final catalog = NarrationCatalog.fromLines(
      [line(), line(locale: NanoAppLocale.ur, text: 'بہت خوب!')],
      locale: NanoAppLocale.ur,
    );

    expect(catalog.length, 1);
    expect(catalog.lookup('celebration-1')!.locale, NanoAppLocale.ur);
    expect(catalog.locale, NanoAppLocale.ur);
  });

  test('hasAudio and containsFileKey describe what is actually there', () {
    final withoutAudio = NarrationCatalog.fromLines(
      [line(withAudio: null)],
      locale: NanoAppLocale.en,
    );
    final withAudio = NarrationCatalog.fromLines(
      [line()],
      locale: NanoAppLocale.en,
    );

    expect(withoutAudio.hasAudio, isFalse);
    expect(withAudio.hasAudio, isTrue);
    expect(withAudio.containsFileKey('sha256:celebration'), isTrue);
    expect(withAudio.containsFileKey('sha256:gone'), isFalse);
    expect(NarrationCatalog.empty.hasAudio, isFalse);
  });
}
