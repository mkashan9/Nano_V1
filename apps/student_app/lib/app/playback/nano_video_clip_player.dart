import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:video_player/video_player.dart';

/// The real reaction clip player (MED-08).
///
/// Lives in the app rather than the design system so a design system shared
/// with admin_web never has to depend on a video plugin. The stage asks for
/// [view] and places whatever it is given, so it never learns what is decoding.
///
/// Silence is enforced here rather than trusted: the volume is set to zero
/// before the first frame, so even a clip that was mastered with an audio track
/// by mistake cannot talk over the narration or surprise a classroom.
class NanoVideoClipPlayer extends ChangeNotifier implements NanoClipPlayer {
  NanoVideoClipPlayer({
    VideoPlayerController Function(Uri url)? open,
  }) : _open = open ?? VideoPlayerController.networkUrl;

  final VideoPlayerController Function(Uri url) _open;

  VideoPlayerController? _controller;
  var _playing = false;
  var _disposed = false;

  @override
  bool get isPlaying => _playing;

  @override
  Widget? get view {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    final size = controller.value.size;
    if (size.isEmpty) return null;
    // Sized to the clip's own frame so a caller can scale it into any slot.
    return SizedBox(
      width: size.width,
      height: size.height,
      child: VideoPlayer(controller),
    );
  }

  @override
  Future<void> play(String url) async {
    if (_disposed) return;
    // One clip at a time: whatever was on screen goes before this arrives.
    await _release();
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    VideoPlayerController? controller;
    try {
      controller = _open(uri);
      _controller = controller;
      controller.addListener(_onControllerChanged);
      await controller.initialize();
      if (_disposed || _controller != controller) {
        await controller.dispose();
        return;
      }
      await controller.setVolume(0);
      await controller.setLooping(false);
      await controller.play();
      _playing = true;
      notifyListeners();
    } catch (_) {
      // A clip that will not decode is a fallback, not a failure: the still art
      // and the caption are already on screen.
      if (_controller == controller) _controller = null;
      try {
        await controller?.dispose();
      } catch (_) {
        // Disposing a controller that never opened is not worth an error.
      }
      if (_playing) {
        _playing = false;
        notifyListeners();
      }
    }
  }

  /// A clip that reaches its end puts the still back on its own, without the
  /// learner having to dismiss it.
  void _onControllerChanged() {
    final controller = _controller;
    if (_disposed || controller == null) return;
    final value = controller.value;
    if (value.hasError) {
      unawaited(stop());
      return;
    }
    if (!value.isInitialized) return;
    final ended = value.position >= value.duration && !value.isPlaying;
    if (ended && _playing) {
      unawaited(stop());
      return;
    }
    // Repaint while frames arrive, so the first frame replaces the still.
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    await _release();
    if (!_playing) return;
    _playing = false;
    notifyListeners();
  }

  Future<void> _release() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    controller.removeListener(_onControllerChanged);
    try {
      await controller.pause();
    } catch (_) {
      // Already gone.
    }
    try {
      await controller.dispose();
    } catch (_) {
      // Already gone.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _release();
    super.dispose();
  }
}