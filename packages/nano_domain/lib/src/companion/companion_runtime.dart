import '../accessibility/accessibility_preferences.dart';
import 'companion_mode.dart';
import 'companion_reaction.dart';

/// How often and how loudly the companion may appear for one experience.
class CompanionPolicy {
  const CompanionPolicy({
    required this.prominent,
    required this.cooldown,
    required this.quietEvents,
  });

  /// Junior: larger, warmer, allowed to comment on ordinary moments.
  static const junior = CompanionPolicy(
    prominent: true,
    cooldown: Duration(seconds: 8),
    quietEvents: {},
  );

  /// Senior: contextual only. Ordinary navigation gets no commentary.
  static const senior = CompanionPolicy(
    prominent: false,
    cooldown: Duration(seconds: 30),
    quietEvents: {
      CompanionEvent.home,
      CompanionEvent.learningEntry,
      CompanionEvent.quizQuestion,
      CompanionEvent.idle,
    },
  );

  final bool prominent;
  final Duration cooldown;

  /// Moments this experience simply does not react to.
  final Set<CompanionEvent> quietEvents;

  bool allows(CompanionEvent event) => !quietEvents.contains(event);

  Duration cooldownFor(CompanionEvent event) =>
      event.isEssential ? Duration.zero : cooldown;
}

/// Why a moment produced nothing. Useful in tests and for a debug surface.
enum CompanionSkipReason {
  /// This experience does not react to the moment at all.
  quietForExperience,

  /// The same moment appeared too recently.
  cooldown,

  /// Classroom Mode allows essential moments only.
  classroomMode,

  /// The session's ordinary-appearance budget is spent.
  sessionBudget,
}

/// The companion state machine (CMP-01, extended by CMP-02).
///
/// Immutable and pure: [notify] returns a new runtime and nothing here reads a
/// clock, a random source, or the network. That is what makes reactions
/// reproducible in tests and identical on two devices, and it is why the app
/// stays usable with every remote companion API down.
///
/// The runtime never computes marks, score, XP, rank, or eligibility. Callers
/// translate a server-authored outcome into a [CompanionEvent] and pass it in.
class CompanionRuntime {
  const CompanionRuntime({
    required this.policy,
    this.rules = CompanionRules.junior,
    this.surface = CompanionSurface.home,
    this.preferences = AccessibilityPreferences.defaults,
    this.companionName = 'Nori',
    this.manifest = CompanionAssetManifest.defaults,
    this.clipsAvailable = false,
    this.clipSlots = const {},
    this.reaction,
    this.lastShownAt = const {},
    this.shownThisSession = 0,
  });

  factory CompanionRuntime.forExperience({
    required bool junior,
    CompanionSurface surface = CompanionSurface.home,
    AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
    String companionName = 'Nori',
    CompanionAssetManifest manifest = CompanionAssetManifest.defaults,
    bool clipsAvailable = false,
    Set<String> clipSlots = const {},
  }) {
    return CompanionRuntime(
      policy: junior ? CompanionPolicy.junior : CompanionPolicy.senior,
      rules: junior ? CompanionRules.junior : CompanionRules.senior,
      surface: surface,
      preferences: preferences,
      companionName: companionName,
      manifest: manifest,
      clipsAvailable: clipsAvailable,
      clipSlots: clipSlots,
    );
  }

  final CompanionPolicy policy;
  final CompanionRules rules;

  /// Where the learner is, which picks the mode.
  final CompanionSurface surface;
  final AccessibilityPreferences preferences;
  final String companionName;
  final CompanionAssetManifest manifest;

  /// Generated clips are an enhancement; false is the normal case.
  final bool clipsAvailable;

  /// Which reaction slots actually have a clip (MED-04). Empty is the normal
  /// case, and it is also MED-02's coarser answer: a library nobody has filled
  /// in and one that has not been listed slot by slot look the same here, which
  /// is why [clipsAvailable] still decides when this is empty.
  final Set<String> clipSlots;

  /// What the surface should be showing, or null for nothing.
  final CompanionReaction? reaction;
  final Map<CompanionEvent, DateTime> lastShownAt;

  /// Ordinary appearances so far this session, rationed by [rules].
  final int shownThisSession;

  bool get isVisible => reaction != null;

  bool get speaks => reaction?.speaks ?? false;

  CompanionMode modeFor(CompanionEvent event) =>
      CompanionMode.resolve(surface: surface, event: event);

  /// Whether a clip exists for one reaction slot (MED-04).
  ///
  /// Authoring a celebration clip must not make the greeting promise one, so
  /// this is a per-slot question. When no slot list has arrived it falls back to
  /// [clipsAvailable], which keeps MED-02's single boolean meaning what it did.
  bool hasClipFor(String slot) =>
      clipSlots.isEmpty ? clipsAvailable : clipSlots.contains(slot);

  /// Why [event] would be skipped at [now], or null when it may appear.
  CompanionSkipReason? skipReason(CompanionEvent event, DateTime now) {
    if (!policy.allows(event)) return CompanionSkipReason.quietForExperience;
    if (preferences.classroomMode && !event.isEssential) {
      return CompanionSkipReason.classroomMode;
    }
    if (rules.countsAgainstBudget(event) &&
        shownThisSession >= rules.maxPerSession) {
      return CompanionSkipReason.sessionBudget;
    }
    final last = lastShownAt[event];
    if (last != null && now.difference(last) < policy.cooldownFor(event)) {
      return CompanionSkipReason.cooldown;
    }
    return null;
  }

  bool isSuppressed(CompanionEvent event, DateTime now) =>
      skipReason(event, now) != null;

  /// Reacts to [event] at [now]. Returns this runtime unchanged when the moment
  /// is suppressed, so a caller can notify freely without tracking cooldowns,
  /// budgets, or Classroom Mode.
  CompanionRuntime notify(
    CompanionEvent event, {
    required DateTime now,
    int seed = 0,
  }) {
    if (isSuppressed(event, now)) return this;
    final mood = CompanionMood.forEvent(event);
    final mode = modeFor(event);
    // The mode is half of the slot, so it has to be settled before the tier can
    // be: whether a clip exists is a question about one reaction, and Quiz Coach
    // celebrating is not the same reaction as Celebration Nori celebrating.
    final clipSlot = CompanionReaction.slotKey(
      mode: mode,
      mood: mood,
      tier: CompanionAssetTier.shortClip,
    );
    final next = CompanionReaction(
      event: event,
      mood: mood,
      script: CompanionScriptBook.select(mood, seed: seed),
      tier: manifest.resolve(
        mood,
        reducedMotion: preferences.effectiveReducedMotion,
        clipAvailable: hasClipFor(clipSlot),
      ),
      mode: mode,
      presentation: rules.presentationFor(surface: surface, event: event),
      companionName: companionName,
      speaks: preferences.effectiveSoundEnabled,
      showsCaption: preferences.captionsEnabled,
      prominent: policy.prominent,
    );
    return _copyWith(
      reaction: next,
      lastShownAt: {...lastShownAt, event: now},
      shownThisSession:
          shownThisSession + (rules.countsAgainstBudget(event) ? 1 : 0),
    );
  }

  /// Reacts to the most important of several moments that arrived together.
  ///
  /// Ties keep the order the caller listed, so a screen reporting the same pair
  /// twice gets the same answer twice.
  CompanionRuntime notifyFirstOf(
    Iterable<CompanionEvent> events, {
    required DateTime now,
    int seed = 0,
  }) {
    CompanionEvent? winner;
    var best = -1;
    for (final event in events) {
      if (isSuppressed(event, now)) continue;
      final priority = rules.priorityOf(surface: surface, event: event);
      if (priority > best) {
        best = priority;
        winner = event;
      }
    }
    if (winner == null) return this;
    return notify(winner, now: now, seed: seed);
  }

  /// Clears the current reaction without forgetting the cooldown.
  CompanionRuntime dismiss() => _copyWith(clearReaction: true);

  /// Moves to another surface, which changes the mode but not the history.
  CompanionRuntime withSurface(CompanionSurface surface) =>
      _copyWith(surface: surface, clearReaction: true);

  CompanionRuntime withPreferences(AccessibilityPreferences preferences) =>
      _copyWith(preferences: preferences);

  /// Learns whether generated clips exist (MED-02).
  ///
  /// The answer arrives after the first screens are already up, so it must not
  /// disturb what is on them: the current reaction, the cooldowns, and the
  /// session budget all survive. Only the tier of a *future* reaction changes.
  CompanionRuntime withClipsAvailable(bool clipsAvailable) =>
      clipsAvailable == this.clipsAvailable
          ? this
          : _copyWith(clipsAvailable: clipsAvailable);

  /// Learns which reactions have a clip (MED-04).
  ///
  /// The same rules as [withClipsAvailable] — nothing on screen moves — with a
  /// finer answer: one authored reaction promises a clip for that reaction only.
  CompanionRuntime withClipSlots(Set<String> slots) {
    if (slots.length == clipSlots.length && slots.containsAll(clipSlots)) {
      return this;
    }
    return _copyWith(
      clipSlots: Set.unmodifiable(slots),
      clipsAvailable: slots.isNotEmpty,
    );
  }

  /// A fresh session: the budget and the cooldowns start over.
  CompanionRuntime newSession() => _copyWith(
        clearReaction: true,
        lastShownAt: const {},
        shownThisSession: 0,
      );

  CompanionRuntime _copyWith({
    CompanionPolicy? policy,
    CompanionRules? rules,
    CompanionSurface? surface,
    AccessibilityPreferences? preferences,
    String? companionName,
    CompanionReaction? reaction,
    bool clearReaction = false,
    Map<CompanionEvent, DateTime>? lastShownAt,
    int? shownThisSession,
    bool? clipsAvailable,
    Set<String>? clipSlots,
  }) {
    return CompanionRuntime(
      policy: policy ?? this.policy,
      rules: rules ?? this.rules,
      surface: surface ?? this.surface,
      preferences: preferences ?? this.preferences,
      companionName: companionName ?? this.companionName,
      manifest: manifest,
      clipsAvailable: clipsAvailable ?? this.clipsAvailable,
      clipSlots: clipSlots ?? this.clipSlots,
      reaction: clearReaction ? null : (reaction ?? this.reaction),
      lastShownAt: lastShownAt ?? this.lastShownAt,
      shownThisSession: shownThisSession ?? this.shownThisSession,
    );
  }
}
