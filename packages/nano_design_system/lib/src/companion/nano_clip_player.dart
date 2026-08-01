/// Plays one reaction clip at a time (MED-04).
///
/// This is a seam, not a player. Nano ships no video plugin yet, and there is
/// nothing to play until a curator films and approves a reaction — so the app is
/// built to the interface and the real implementation lands with the first
/// approved clip. The consequence is deliberate: with no player attached, the
/// play affordance never appears and every reaction keeps local art, which is
/// the same experience a reduced-motion learner already has.
///
/// Three rules an implementation must keep:
///
///   * **One clip at a time.** Starting a clip stops the previous one. Two
///     overlapping reactions are noise, and a stage that has moved on should not
///     keep playing behind it.
///   * **Never throw at a caller.** A clip that will not play is a fallback, not
///     an error: the local art and the caption are already on screen.
///   * **Silent.** A reaction clip carries no audio track. Audio focus belongs
///     to narration (MED-03); a clip must never seize it. Reduced motion is
///     decided before play is offered, so this seam never has to know about it.
abstract class NanoClipPlayer {
  /// Play [url]. Returns when playback has started, not when it has finished, so
  /// a caller is never blocked waiting for a short clip to end.
  Future<void> play(String url);

  Future<void> stop();

  /// Whether something is playing now, for a caller that shows a stop control.
  bool get isPlaying;
}

/// Records what would have been played (MED-04).
///
/// Used in tests, and as the honest default: it satisfies the contract without
/// pretending to show video. A screen driven by this behaves exactly as it will
/// with a real player, which is what makes the wiring testable before the plugin
/// exists.
class NanoRecordingClipPlayer implements NanoClipPlayer {
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
