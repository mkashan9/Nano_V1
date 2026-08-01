/// Plays one narration clip at a time (MED-03).
///
/// This is a seam, not a player. Nano ships no audio plugin yet, and there is
/// nothing to play until a curator records and approves a line — so the app is
/// built to the interface and the real implementation lands with the first
/// approved recording. The consequence is deliberate: with no player attached, the
/// listen affordance never appears and every line is read rather than heard, which
/// is the same experience a muted learner already has.
///
/// Two rules an implementation must keep:
///
///   * **One voice at a time.** Starting a clip stops the previous one. Handbook
///     10 gives the Guide a single voice, and two overlapping lines are noise.
///   * **Never throw at a caller.** A clip that will not play is a fallback, not
///     an error: the caption is already on screen.
abstract class NanoVoicePlayer {
  /// Play [url]. Returns when playback has started, not when it has finished, so
  /// a caller is never blocked waiting for a sentence to end.
  Future<void> play(String url);

  Future<void> stop();

  /// Whether something is playing now, for a caller that shows a stop control.
  bool get isPlaying;
}

/// Records what would have been played (MED-03).
///
/// Used in tests, and as the honest default: it satisfies the contract without
/// pretending to make sound. A screen driven by this behaves exactly as it will
/// with a real player, which is what makes the wiring testable before the plugin
/// exists.
class NanoRecordingVoicePlayer implements NanoVoicePlayer {
  final played = <String>[];
  var stopCount = 0;
  var _playing = false;

  @override
  bool get isPlaying => _playing;

  @override
  Future<void> play(String url) async {
    // Kept, not logged: a signed URL is a credential.
    played.add(url);
    _playing = true;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _playing = false;
  }
}
