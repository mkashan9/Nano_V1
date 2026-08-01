import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nano_design_system/nano_design_system.dart';

/// The real narration voice (MED-08).
///
/// Lives in the app rather than the design system so a design system shared
/// with admin_web never has to depend on an audio plugin.
///
/// Everything here is written to the seam's promise that a caller is never
/// handed an error. A missing file, an expired URL, a device that refuses to
/// open an audio session, a platform with no implementation at all — each one
/// ends with the caption on screen and nothing playing, which is exactly the
/// experience a muted learner already has.
class NanoAudioVoicePlayer extends ChangeNotifier implements NanoVoicePlayer {
  NanoAudioVoicePlayer({AudioPlayer? player})
      : _player = player ?? AudioPlayer() {
    _sub = _player.playerStateStream.listen(
      (state) {
        final playing = state.playing &&
            state.processingState != ProcessingState.completed &&
            state.processingState != ProcessingState.idle;
        if (playing == _playing) return;
        _playing = playing;
        notifyListeners();
      },
      // A stream that breaks must not take the app with it.
      onError: (_) => _settle(),
    );
  }

  final AudioPlayer _player;
  StreamSubscription<PlayerState>? _sub;
  var _playing = false;
  var _disposed = false;

  @override
  bool get isPlaying => _playing;

  @override
  Future<void> play(String url) async {
    if (_disposed) return;
    try {
      // One voice at a time: whatever was speaking stops before this starts.
      await _player.stop();
      await _player.setUrl(url);
      // Not awaited: play() completes when the sentence ends, and a caller must
      // not be blocked for the length of a line.
      unawaited(_player.play().catchError((_) => _settle()));
      _playing = true;
      notifyListeners();
    } catch (_) {
      // The caption is already on screen; that is the fallback.
      _settle();
    }
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    try {
      await _player.stop();
    } catch (_) {
      // Stopping something that will not stop is not worth an error either.
    }
    _settle();
  }

  void _settle() {
    if (_disposed || !_playing) return;
    _playing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
