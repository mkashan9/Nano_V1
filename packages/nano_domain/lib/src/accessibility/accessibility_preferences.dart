/// User/accessibility preferences shared across apps (persisted later in STU/profile).
class AccessibilityPreferences {
  const AccessibilityPreferences({
    this.textScale = 1.0,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.reducedMotion = false,
    this.captionsEnabled = true,
    this.classroomMode = false,
  });

  /// Manual text scale multiplier on top of system scaling (clamped in UI).
  final double textScale;
  final bool soundEnabled;
  final bool hapticsEnabled;

  /// When true, non-essential motion becomes instant/static fades.
  final bool reducedMotion;
  final bool captionsEnabled;

  /// Classroom Mode suppresses non-essential interruptions and feedback noise.
  final bool classroomMode;

  bool get effectiveSoundEnabled =>
      soundEnabled && !classroomMode;

  bool get effectiveHapticsEnabled =>
      hapticsEnabled && !classroomMode;

  bool get effectiveReducedMotion => reducedMotion || classroomMode;

  AccessibilityPreferences copyWith({
    double? textScale,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? reducedMotion,
    bool? captionsEnabled,
    bool? classroomMode,
  }) {
    return AccessibilityPreferences(
      textScale: textScale ?? this.textScale,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      captionsEnabled: captionsEnabled ?? this.captionsEnabled,
      classroomMode: classroomMode ?? this.classroomMode,
    );
  }

  static const defaults = AccessibilityPreferences();
}
