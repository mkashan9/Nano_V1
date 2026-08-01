import 'package:flutter/widgets.dart';

/// Plays one reaction clip at a time (MED-04, made real in MED-08).
///
/// The interface stays in the design system and the plugin-backed
/// implementation lives in the app, so a design system shared with admin_web
/// never has to depend on a video plugin. A stage asks for [view] and places
/// whatever it is given; it never learns what is decoding behind it.
///
/// Four rules an implementation must keep:
///
///   * **One clip at a time.** Starting a clip stops the previous one. Two
///     overlapping reactions are noise, and a stage that has moved on should not
///     keep playing behind it.
///   * **Never throw at a caller.** A clip that will not play is a fallback, not
///     an error: the still art and the caption are already on screen.
///   * **Silent.** A reaction clip carries no audio track. Audio focus belongs
///     to narration (MED-03); a clip must never seize it. Reduced motion is
///     decided before play is offered, so this seam never has to know about it.
///   * **Announce every change.** Playback ends on its own, and the stage has to
///     return to the still when it does, so an implementation notifies on start,
///     on stop, and on reaching the end.
abstract class NanoClipPlayer implements Listenable {
  /// Play [url]. Returns when playback has started, not when it has finished, so
  /// a caller is never blocked waiting for a short clip to end.
  Future<void> play(String url);

  Future<void> stop();

  /// Whether something is playing now, for a caller that shows a stop control.
  bool get isPlaying;

  /// The surface showing the clip playing now, or null when there is nothing to
  /// show. A caller sizes and clips it; the widget itself only has to fill the
  /// space it is given.
  Widget? get view;
}

/// Records what would have been played (MED-04).
///
/// Used in tests, and as the honest default: it satisfies the contract without
/// pretending to show video. A screen driven by this behaves exactly as it will
/// with a real player, which is what makes the wiring testable without a plugin.
class NanoRecordingClipPlayer extends ChangeNotifier implements NanoClipPlayer {
  final played = <String>[];
  var stopCount = 0;
  var _playing = false;

  @override
  bool get isPlaying => _playing;

  /// Nothing to show: this double decodes nothing. A stage falls back to the
  /// still, which is exactly what it does when a real player cannot decode.
  @override
  Widget? get view => null;

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
