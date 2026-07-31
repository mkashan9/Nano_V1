import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nano_domain/nano_domain.dart';

/// Sound + haptics feedback gateway. Audio assets arrive in media modules;
/// R0 records intent and respects preference gates.
class NanoFeedback {
  NanoFeedback({
    AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
    this.onSound,
  }) : _preferences = preferences;

  AccessibilityPreferences _preferences;
  final void Function(NanoSoundCue cue)? onSound;

  /// Last cue requested (for tests).
  NanoSoundCue? lastSoundCue;
  int hapticCount = 0;

  AccessibilityPreferences get preferences => _preferences;

  void updatePreferences(AccessibilityPreferences preferences) {
    _preferences = preferences;
  }

  Future<void> playSound(NanoSoundCue cue) async {
    if (!_preferences.effectiveSoundEnabled) return;
    lastSoundCue = cue;
    onSound?.call(cue);
    if (kDebugMode) {
      debugPrint('NanoFeedback.sound:${cue.name}');
    }
  }

  Future<void> hapticLight() async {
    if (!_preferences.effectiveHapticsEnabled) return;
    hapticCount++;
    await HapticFeedback.lightImpact();
  }

  Future<void> hapticSelection() async {
    if (!_preferences.effectiveHapticsEnabled) return;
    hapticCount++;
    await HapticFeedback.selectionClick();
  }

  Future<void> success() async {
    await playSound(NanoSoundCue.success);
    await hapticLight();
  }

  Future<void> error() async {
    await playSound(NanoSoundCue.error);
    await hapticSelection();
  }
}
