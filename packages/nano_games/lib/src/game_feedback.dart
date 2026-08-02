import 'package:nano_domain/nano_domain.dart';

/// Optional feedback sink for game surfaces (sound/haptics).
abstract class GameFeedbackSink {
  Future<void> tick();
  Future<void> success();
}

/// Counts cues for tests; no platform channels.
class CountingGameFeedback implements GameFeedbackSink {
  CountingGameFeedback(this.settings);

  GamePlaySettings settings;
  var tickCount = 0;
  var successCount = 0;
  var soundAttempts = 0;
  var hapticAttempts = 0;

  @override
  Future<void> tick() async {
    if (settings.effectiveSoundEnabled) soundAttempts++;
    if (settings.effectiveHapticsEnabled) {
      hapticAttempts++;
      tickCount++;
    }
  }

  @override
  Future<void> success() async {
    if (settings.effectiveSoundEnabled) soundAttempts++;
    if (settings.effectiveHapticsEnabled) {
      hapticAttempts++;
      successCount++;
    }
  }
}
