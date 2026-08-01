import 'package:nano_domain/nano_domain.dart';

/// Why a line is being read rather than heard (MED-03).
///
/// Every one of these is an ordinary outcome. None is shown to a learner: the
/// caption is on screen either way, and the difference only matters to whoever is
/// deciding what to record next.
enum NarrationFallback {
  /// Audio exists for exactly the words on screen, and sound is allowed.
  none,

  /// Nobody has authored this line in the database yet.
  noLine,

  /// The line is authored but has never been recorded, or not in this language.
  noRecording,

  /// A recording exists, but the wording has moved on since it was made. Playing
  /// it would say something other than the caption underneath it.
  wordingChanged,

  /// The line names the learner's companion, so it can never be pre-recorded.
  personalised,

  /// Sound is off, or Classroom Mode is on. The words are unaffected.
  soundOff,
}

/// What the Learning Guide should do with a reaction (MED-03).
///
/// [caption] is never empty when a reaction has words, and it comes from the
/// script that ships with the app rather than from the network — so an offline
/// device, a failed fetch, and a fully recorded library all put the same text on
/// screen. [audio] is the extra.
class NarrationChoice {
  const NarrationChoice({
    required this.caption,
    this.audio,
    this.fallback = NarrationFallback.none,
  });

  final String caption;

  /// Non-null only when it is safe to play: the recording says these exact words
  /// in this language, and the learner has sound on.
  final NarrationAudio? audio;

  final NarrationFallback fallback;

  bool get canSpeak => audio != null;
}

/// Published narration for one language (MED-03).
///
/// Deliberately per-language with **no fallback between languages**. That is the
/// opposite of [CompanionAssetCatalog], and the difference is the point: a silent
/// picture is reusable across languages, a sentence is not. English audio under an
/// Urdu caption would be worse than silence.
class NarrationCatalog {
  const NarrationCatalog._(this.locale, this._bySlug);

  factory NarrationCatalog.fromLines(
    Iterable<NarrationLine> lines, {
    required NanoAppLocale locale,
  }) {
    final bySlug = <String, NarrationLine>{};
    for (final line in lines) {
      if (line.locale != locale) continue;
      bySlug[line.slug] = line;
    }
    return NarrationCatalog._(locale, bySlug);
  }

  static const empty = NarrationCatalog._(NanoAppLocale.en, {});

  final NanoAppLocale locale;
  final Map<String, NarrationLine> _bySlug;

  int get length => _bySlug.length;

  Iterable<NarrationLine> get lines => _bySlug.values;

  bool get hasAudio => _bySlug.values.any((line) => line.hasAudio);

  NarrationLine? lookup(String slug) => _bySlug[slug];

  /// Whether [key] still identifies a file here, so a cache can drop URLs for
  /// recordings a refresh has replaced.
  bool containsFileKey(String key) =>
      _bySlug.values.any((line) => line.audio?.fileKey == key);

  /// Decide what to show and whether to speak.
  ///
  /// The caption is resolved from the local script book first and is returned
  /// whatever else happens. Then audio has to earn its place: it must exist, the
  /// line must not be personalised, the recorded wording must match the caption,
  /// and sound must be allowed.
  NarrationChoice choose(
    CompanionReaction reaction, {
    String? companionName,
    bool? soundEnabled,
  }) {
    final name = companionName ?? reaction.companionName;
    final caption = reaction.captionFor(locale, companionName: name);
    // The runtime has already folded sound, Classroom Mode, and the learner's
    // preference into `speaks`, so that is the default rather than "on".
    final canHear = soundEnabled ?? reaction.speaks;

    // The template is checked, not the caption: by the time a name has been
    // filled in there is no placeholder left to notice.
    if (reaction.script.isPersonalised) {
      return NarrationChoice(
        caption: caption,
        fallback: NarrationFallback.personalised,
      );
    }

    final line = lookup(reaction.script.id);
    if (line == null) {
      return NarrationChoice(caption: caption, fallback: NarrationFallback.noLine);
    }

    final audio = line.audio;
    if (audio == null) {
      return NarrationChoice(
        caption: caption,
        fallback: NarrationFallback.noRecording,
      );
    }

    // The server's published wording is the words that were recorded. If the app
    // is showing something else — an update in flight either way — the two would
    // disagree out loud, and the caption wins.
    if (!_saysTheSameThing(line.text, caption)) {
      return NarrationChoice(
        caption: caption,
        fallback: NarrationFallback.wordingChanged,
      );
    }

    if (!canHear) {
      return NarrationChoice(caption: caption, fallback: NarrationFallback.soundOff);
    }

    return NarrationChoice(caption: caption, audio: audio);
  }

  /// Punctuation and spacing are not worth a mismatch; different words are.
  static bool _saysTheSameThing(String a, String b) =>
      _normalise(a) == _normalise(b);

  static String _normalise(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
