import '../l10n/nano_app_locale.dart';
import 'companion_mode.dart';

/// Moments the companion may respond to (CMP-01).
///
/// The list is deliberately closed: a surface asks for a known moment rather
/// than inventing prose, so guidance stays consistent across the app.
enum CompanionEvent {
  appOpen,
  home,
  learningEntry,
  newWorld,
  videoStart,
  videoComplete,
  quizStart,
  quizQuestion,
  quizComplete,
  resultPassed,
  resultNeedsReview,
  achievement,
  levelUp,
  returnFromInactivity,
  emptyState,
  idle;

  /// Maps a server-authored outcome to a moment.
  ///
  /// The companion never decides whether an attempt passed; it is told.
  static CompanionEvent forOutcome({required bool passed}) =>
      passed ? CompanionEvent.resultPassed : CompanionEvent.resultNeedsReview;

  /// Moments the learner must not miss, so they ignore cooldowns.
  bool get isEssential => switch (this) {
        CompanionEvent.quizComplete ||
        CompanionEvent.resultPassed ||
        CompanionEvent.resultNeedsReview ||
        CompanionEvent.achievement ||
        CompanionEvent.levelUp =>
          true,
        _ => false,
      };
}

/// The core reaction set: greeting, idle, point, thinking, gentle retry, and a
/// small celebration. Nothing louder exists yet by design.
enum CompanionMood {
  greeting,
  idle,
  point,
  thinking,
  gentleRetry,
  celebration;

  static CompanionMood forEvent(CompanionEvent event) => switch (event) {
        CompanionEvent.appOpen ||
        CompanionEvent.home ||
        CompanionEvent.returnFromInactivity =>
          CompanionMood.greeting,
        CompanionEvent.learningEntry ||
        CompanionEvent.newWorld ||
        CompanionEvent.videoStart ||
        CompanionEvent.quizStart ||
        CompanionEvent.emptyState =>
          CompanionMood.point,
        CompanionEvent.quizQuestion => CompanionMood.thinking,
        CompanionEvent.resultNeedsReview => CompanionMood.gentleRetry,
        CompanionEvent.videoComplete ||
        CompanionEvent.quizComplete ||
        CompanionEvent.resultPassed ||
        CompanionEvent.achievement ||
        CompanionEvent.levelUp =>
          CompanionMood.celebration,
        CompanionEvent.idle => CompanionMood.idle,
      };
}

/// Asset ladder from the handbook: local art first, generated clips last.
enum CompanionAssetTier {
  staticArt,
  localAnimation,
  shortClip;

  /// Everything below [shortClip] ships with the app.
  bool get isLocal => this != CompanionAssetTier.shortClip;
}

/// One line the companion can say, with its caption text.
///
/// `{name}` is replaced with the learner's companion name so a renamed
/// companion never talks about itself in the third person.
class CompanionScript {
  const CompanionScript({
    required this.id,
    required this.text,
    this.textUr,
  });

  final String id;
  final String text;
  final String? textUr;

  String textFor(NanoAppLocale locale, {String companionName = 'Nori'}) {
    return templateFor(locale).replaceAll('{name}', companionName);
  }

  /// The line before any name is filled in.
  String templateFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (textUr?.isNotEmpty ?? false)
          ? textUr!
          : text;

  /// Whether the line names the learner's companion (MED-03).
  ///
  /// A personalised line can never be pre-recorded: the recording would say one
  /// child's companion name to every other child. Checked across both languages,
  /// because a line is one line and it is either personal or it is not.
  bool get isPersonalised =>
      text.contains('{') || (textUr?.contains('{') ?? false);
}

/// Local script book. Each mood has an ordered list, and selection is by index
/// rather than randomness so the same moment reads the same way in tests and on
/// two different devices.
abstract final class CompanionScriptBook {
  static const core = <CompanionMood, List<CompanionScript>>{
    CompanionMood.greeting: [
      CompanionScript(
        id: 'greeting-1',
        text: 'Hello! {name} is here whenever you are ready.',
        textUr: 'سلام! {name} آپ کے ساتھ ہے۔',
      ),
      CompanionScript(
        id: 'greeting-2',
        text: 'Good to see you again.',
        textUr: 'آپ کو دوبارہ دیکھ کر خوشی ہوئی۔',
      ),
    ],
    CompanionMood.idle: [
      CompanionScript(
        id: 'idle-1',
        text: 'Take your time.',
        textUr: 'آرام سے کریں۔',
      ),
    ],
    CompanionMood.point: [
      CompanionScript(
        id: 'point-1',
        text: 'Start here.',
        textUr: 'یہاں سے شروع کریں۔',
      ),
      CompanionScript(
        id: 'point-2',
        text: 'This one is next.',
        textUr: 'اگلا یہ ہے۔',
      ),
    ],
    CompanionMood.thinking: [
      CompanionScript(
        id: 'thinking-1',
        text: 'Read it once more, then choose.',
        textUr: 'ایک بار پھر پڑھیں، پھر انتخاب کریں۔',
      ),
    ],
    CompanionMood.gentleRetry: [
      CompanionScript(
        id: 'retry-1',
        text: 'Some of these need another look. We can try again.',
        textUr: 'کچھ سوال دوبارہ دیکھنے ہیں۔ ہم پھر کوشش کریں گے۔',
      ),
    ],
    CompanionMood.celebration: [
      CompanionScript(
        id: 'celebration-1',
        text: 'Nicely done!',
        textUr: 'بہت خوب!',
      ),
      CompanionScript(
        id: 'celebration-2',
        text: 'That was good work.',
        textUr: 'یہ اچھا کام تھا۔',
      ),
    ],
  };

  /// Deterministic pick: the same [seed] always yields the same line.
  static CompanionScript select(
    CompanionMood mood, {
    int seed = 0,
    Map<CompanionMood, List<CompanionScript>> book = core,
  }) {
    final lines = book[mood] ?? const <CompanionScript>[];
    if (lines.isEmpty) return _fallback;
    return lines[seed.abs() % lines.length];
  }

  static const _fallback = CompanionScript(id: 'fallback', text: '');
}

/// Which tier of art exists locally for each mood.
///
/// Every mood resolves to something without a network call, which is what keeps
/// the app usable when generated media is unavailable.
class CompanionAssetManifest {
  const CompanionAssetManifest({this.tiers = _default});

  static const _default = <CompanionMood, CompanionAssetTier>{
    CompanionMood.greeting: CompanionAssetTier.localAnimation,
    CompanionMood.idle: CompanionAssetTier.staticArt,
    CompanionMood.point: CompanionAssetTier.staticArt,
    CompanionMood.thinking: CompanionAssetTier.staticArt,
    CompanionMood.gentleRetry: CompanionAssetTier.staticArt,
    CompanionMood.celebration: CompanionAssetTier.shortClip,
  };

  final Map<CompanionMood, CompanionAssetTier> tiers;

  /// Highest tier available, dropped to static art when motion is reduced or a
  /// clip would need a remote asset that is not there.
  ///
  /// [clipAvailable] is about *this* reaction's slot, not the library as a whole
  /// (MED-04): authoring one clip promises a clip for that reaction and for
  /// nothing else.
  CompanionAssetTier resolve(
    CompanionMood mood, {
    bool reducedMotion = false,
    bool clipAvailable = false,
  }) {
    final best = tiers[mood] ?? CompanionAssetTier.staticArt;
    if (reducedMotion) return CompanionAssetTier.staticArt;
    if (best == CompanionAssetTier.shortClip && !clipAvailable) {
      return CompanionAssetTier.localAnimation;
    }
    return best;
  }

  static const defaults = CompanionAssetManifest();
}

/// A resolved reaction: what to show, what to say, and how loudly.
class CompanionReaction {
  const CompanionReaction({
    required this.event,
    required this.mood,
    required this.script,
    required this.tier,
    this.mode = CompanionMode.guide,
    this.presentation = CompanionPresentation.inline,
    this.companionName = 'Nori',
    this.speaks = false,
    this.showsCaption = true,
    this.prominent = false,
  });

  final CompanionEvent event;
  final CompanionMood mood;
  final CompanionScript script;
  final CompanionAssetTier tier;

  /// Which controlled variant is on screen (CMP-02).
  final CompanionMode mode;

  /// Inline guidance or a rare framed story card (CMP-02).
  final CompanionPresentation presentation;

  /// The learner's name for the companion, carried so a caption cannot be
  /// rendered with the default name by accident.
  final String companionName;

  /// Voice is allowed. Classroom Mode and muted sound both turn this off.
  final bool speaks;

  /// Captions stay on when the voice is off, so the line is never lost.
  final bool showsCaption;

  /// Junior guidance is larger and more central than Senior's.
  final bool prominent;

  /// Stable key for art lookup and for goldens. Mode is part of it because a
  /// mode is a different set of art for the same mood.
  String get assetKey => slotKey(mode: mode, mood: mood, tier: tier);

  /// The same key, built before a reaction exists to carry it. Clip
  /// availability is decided per slot (MED-04), so the runtime has to name the
  /// slot it is about to ask for while it is still deciding the tier.
  static String slotKey({
    required CompanionMode mode,
    required CompanionMood mood,
    required CompanionAssetTier tier,
  }) =>
      '${mode.name}_${mood.name}_${tier.name}';

  String captionFor(NanoAppLocale locale, {String? companionName}) =>
      script.textFor(
        locale,
        companionName: companionName ?? this.companionName,
      );
}
