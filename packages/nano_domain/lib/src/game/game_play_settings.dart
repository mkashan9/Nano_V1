import '../accessibility/accessibility_preferences.dart';

/// GME-06 play settings derived from accessibility preferences.
class GamePlaySettings {
  const GamePlaySettings({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.reducedMotion = false,
    this.classroomMode = false,
  });

  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool reducedMotion;
  final bool classroomMode;

  bool get effectiveSoundEnabled => soundEnabled && !classroomMode;
  bool get effectiveHapticsEnabled => hapticsEnabled && !classroomMode;
  bool get effectiveReducedMotion => reducedMotion || classroomMode;

  Map<String, dynamic> toBridgeJson() => {
        'sound_enabled': effectiveSoundEnabled,
        'haptics_enabled': effectiveHapticsEnabled,
        'reduced_motion': effectiveReducedMotion,
        'classroom_mode': classroomMode,
      };

  factory GamePlaySettings.fromAccessibility(AccessibilityPreferences prefs) {
    return GamePlaySettings(
      soundEnabled: prefs.soundEnabled,
      hapticsEnabled: prefs.hapticsEnabled,
      reducedMotion: prefs.reducedMotion,
      classroomMode: prefs.classroomMode,
    );
  }

  static const defaults = GamePlaySettings();
}
