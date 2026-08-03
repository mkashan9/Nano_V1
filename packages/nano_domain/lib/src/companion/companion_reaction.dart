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
  subjectSelected,
  topicOpened,
  newWorld,
  videoStart,
  videoComplete,
  longVideoRefresh,
  quizStart,
  quizQuestion,
  quizComplete,
  quizCorrect,
  quizWrong,
  quizRepeatedMistake,
  hintOffered,
  resultPassed,
  resultNeedsReview,
  achievement,
  levelUp,
  gameCompleted,
  personalBest,
  missionCompleted,
  streakMilestone,
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
    CompanionEvent.levelUp ||
    CompanionEvent.missionCompleted ||
    CompanionEvent.streakMilestone ||
    CompanionEvent.personalBest => true,
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
    CompanionEvent.returnFromInactivity => CompanionMood.greeting,
    CompanionEvent.learningEntry ||
    CompanionEvent.subjectSelected ||
    CompanionEvent.topicOpened ||
    CompanionEvent.newWorld ||
    CompanionEvent.videoStart ||
    CompanionEvent.quizStart ||
    CompanionEvent.emptyState ||
    CompanionEvent.hintOffered => CompanionMood.point,
    CompanionEvent.quizQuestion ||
    CompanionEvent.longVideoRefresh => CompanionMood.thinking,
    CompanionEvent.resultNeedsReview ||
    CompanionEvent.quizWrong ||
    CompanionEvent.quizRepeatedMistake => CompanionMood.gentleRetry,
    CompanionEvent.videoComplete ||
    CompanionEvent.quizComplete ||
    CompanionEvent.quizCorrect ||
    CompanionEvent.resultPassed ||
    CompanionEvent.achievement ||
    CompanionEvent.levelUp ||
    CompanionEvent.gameCompleted ||
    CompanionEvent.personalBest ||
    CompanionEvent.missionCompleted ||
    CompanionEvent.streakMilestone => CompanionMood.celebration,
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
  const CompanionScript({required this.id, required this.text, this.textUr});

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
        id: 'onboarding-1',
        text: 'Hey. I’m here to help you learn, play, and keep moving forward.',
        textUr: 'سلام۔ میں سیکھنے، کھیلنے اور آگے بڑھنے میں مدد کے لیے ہوں۔',
      ),
      CompanionScript(
        id: 'greeting-1',
        text: 'Welcome back. Ready for your next step?',
        textUr: 'خوش آمدید۔ اگلے قدم کے لیے تیار؟',
      ),
      CompanionScript(
        id: 'greeting-2',
        text: 'Good to see you again. We can continue whenever you’re ready.',
        textUr: 'آپ کو دوبارہ دیکھ کر خوشی ہوئی۔ جب چاہیں جاری رکھیں۔',
      ),
    ],
    CompanionMood.idle: [
      CompanionScript(
        id: 'video-start-1',
        text: 'Take your time. I’ll be here when you finish.',
      ),
      CompanionScript(id: 'idle-1', text: 'Take your time.'),
    ],
    CompanionMood.point: [
      CompanionScript(
        id: 'learning-entry-1',
        text:
            'Pick something that looks interesting, and we’ll start from there.',
      ),
      CompanionScript(id: 'point-1', text: 'Start here.'),
      CompanionScript(
        id: 'quiz-intro-1',
        text: 'Let’s see what you remember. One question at a time.',
      ),
    ],
    CompanionMood.thinking: [
      CompanionScript(
        id: 'refresh-1',
        text: 'Quick break. Stretch, breathe, and continue when you’re ready.',
      ),
      CompanionScript(id: 'thinking-1', text: 'Read it once, then choose.'),
    ],
    CompanionMood.gentleRetry: [
      CompanionScript(
        id: 'retry-1',
        text: 'That one was tricky. Take another look. You’ve got this.',
        textUr: 'یہ مشکل تھا۔ دوبارہ دیکھیں۔ آپ کر سکتے ہیں۔',
      ),
      CompanionScript(
        id: 'retry-2',
        text: 'Let’s slow it down. Look for the clue before choosing again.',
        textUr: 'آہستہ کریں۔ دوبارہ انتخاب سے پہلے اشارہ تلاش کریں۔',
      ),
    ],
    CompanionMood.celebration: [
      CompanionScript(
        id: 'video-complete-1',
        text:
            'Nice work. You finished the lesson. Let’s check what you remember.',
      ),
      CompanionScript(
        id: 'quiz-complete-1',
        text: 'Well done. You stayed focused and finished strong.',
      ),
      CompanionScript(
        id: 'achievement-1',
        text: 'You earned this. Keep going.',
      ),
      CompanionScript(
        id: 'level-up-1',
        text: 'Level up. You earned it, one step at a time.',
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
  ///
  /// The map is the floor the app can always reach without a network. An
  /// approved clip may lift a mood one rung above that floor and no further
  /// (MED-08), so a mood that already animates locally can become a clip while
  /// the routine moods stay still art however much is published. Which moods
  /// can carry a clip is therefore a curation decision — somebody has to author
  /// and approve one — rather than a promise made here.
  CompanionAssetTier resolve(
    CompanionMood mood, {
    bool reducedMotion = false,
    bool clipAvailable = false,
  }) {
    final best = tiers[mood] ?? CompanionAssetTier.staticArt;
    if (reducedMotion) return CompanionAssetTier.staticArt;
    if (best == CompanionAssetTier.shortClip) {
      return clipAvailable
          ? CompanionAssetTier.shortClip
          : CompanionAssetTier.localAnimation;
    }
    if (best == CompanionAssetTier.localAnimation && clipAvailable) {
      return CompanionAssetTier.shortClip;
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
  }) => '${mode.name}_${mood.name}_${tier.name}';

  String captionFor(NanoAppLocale locale, {String? companionName}) => script
      .textFor(locale, companionName: companionName ?? this.companionName);
}
