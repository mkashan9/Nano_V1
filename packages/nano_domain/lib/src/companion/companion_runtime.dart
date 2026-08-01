import '../accessibility/accessibility_preferences.dart';
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

/// The companion state machine (CMP-01).
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
    this.preferences = AccessibilityPreferences.defaults,
    this.companionName = 'Nori',
    this.manifest = CompanionAssetManifest.defaults,
    this.clipsAvailable = false,
    this.reaction,
    this.lastShownAt = const {},
  });

  factory CompanionRuntime.forExperience({
    required bool junior,
    AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
    String companionName = 'Nori',
    CompanionAssetManifest manifest = CompanionAssetManifest.defaults,
    bool clipsAvailable = false,
  }) {
    return CompanionRuntime(
      policy: junior ? CompanionPolicy.junior : CompanionPolicy.senior,
      preferences: preferences,
      companionName: companionName,
      manifest: manifest,
      clipsAvailable: clipsAvailable,
    );
  }

  final CompanionPolicy policy;
  final AccessibilityPreferences preferences;
  final String companionName;
  final CompanionAssetManifest manifest;

  /// Generated clips are an enhancement; false is the normal case.
  final bool clipsAvailable;

  /// What the surface should be showing, or null for nothing.
  final CompanionReaction? reaction;
  final Map<CompanionEvent, DateTime> lastShownAt;

  bool get isVisible => reaction != null;

  bool get speaks => reaction?.speaks ?? false;

  /// True when [event] would be skipped: either this experience stays quiet
  /// about it, or it appeared too recently.
  bool isSuppressed(CompanionEvent event, DateTime now) {
    if (!policy.allows(event)) return true;
    final last = lastShownAt[event];
    if (last == null) return false;
    return now.difference(last) < policy.cooldownFor(event);
  }

  /// Reacts to [event] at [now]. Returns this runtime unchanged when the moment
  /// is suppressed, so a caller can notify freely without tracking cooldowns.
  CompanionRuntime notify(
    CompanionEvent event, {
    required DateTime now,
    int seed = 0,
  }) {
    if (isSuppressed(event, now)) return this;
    final mood = CompanionMood.forEvent(event);
    final next = CompanionReaction(
      event: event,
      mood: mood,
      script: CompanionScriptBook.select(mood, seed: seed),
      tier: manifest.resolve(
        mood,
        reducedMotion: preferences.effectiveReducedMotion,
        clipsAvailable: clipsAvailable,
      ),
      companionName: companionName,
      speaks: preferences.effectiveSoundEnabled,
      showsCaption: preferences.captionsEnabled,
      prominent: policy.prominent,
    );
    return _copyWith(
      reaction: next,
      lastShownAt: {...lastShownAt, event: now},
    );
  }

  /// Clears the current reaction without forgetting the cooldown.
  CompanionRuntime dismiss() => _copyWith(clearReaction: true);

  CompanionRuntime withPreferences(AccessibilityPreferences preferences) =>
      _copyWith(preferences: preferences);

  CompanionRuntime _copyWith({
    CompanionPolicy? policy,
    AccessibilityPreferences? preferences,
    String? companionName,
    CompanionReaction? reaction,
    bool clearReaction = false,
    Map<CompanionEvent, DateTime>? lastShownAt,
  }) {
    return CompanionRuntime(
      policy: policy ?? this.policy,
      preferences: preferences ?? this.preferences,
      companionName: companionName ?? this.companionName,
      manifest: manifest,
      clipsAvailable: clipsAvailable,
      reaction: clearReaction ? null : (reaction ?? this.reaction),
      lastShownAt: lastShownAt ?? this.lastShownAt,
    );
  }
}
