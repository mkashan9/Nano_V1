import 'package:flutter/widgets.dart';

/// Plays one narration clip at a time (MED-03, made real in MED-08).
///
/// The interface stays in the design system and the plugin-backed
/// implementation lives in the app, so a design system shared with admin_web
/// never has to depend on an audio plugin.
///
/// Three rules an implementation must keep:
///
///   * **One voice at a time.** Starting a clip stops the previous one. Handbook
///     10 gives the Guide a single voice, and two overlapping lines are noise.
///   * **Never throw at a caller.** A clip that will not play is a fallback, not
///     an error: the caption is already on screen.
///   * **Announce every change.** A line ends on its own, and a caller showing a
///     stop control has to know, so an implementation notifies on start, on
///     stop, and on reaching the end.
abstract class NanoVoicePlayer implements Listenable {
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
/// with a real player, which is what makes the wiring testable without a plugin.
class NanoRecordingVoicePlayer extends ChangeNotifier
    implements NanoVoicePlayer {
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
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _playing = false;
    notifyListeners();
  }
}
