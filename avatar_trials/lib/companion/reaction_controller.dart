import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Reaction states adapted from Yofardev's avatar animation approach:
/// idle loop + queued specials + interruptible playback.
/// No lip-sync / TTS — matches the Nori decision.
enum CompanionMood {
  idle,
  happy,
  thinking,
  celebrate,
  encourage,
  confused,
  wave,
}

class CompanionReaction {
  const CompanionReaction({
    required this.mood,
    this.duration = const Duration(milliseconds: 1600),
  });

  final CompanionMood mood;
  final Duration duration;
}

/// Lightweight stand-in for Yofardev's AvatarAnimationService + interruption flow.
class CompanionReactionController extends ChangeNotifier {
  CompanionReactionController() {
    _scheduleIdlePulse();
  }

  final Queue<CompanionReaction> _queue = Queue<CompanionReaction>();
  CompanionMood _mood = CompanionMood.idle;
  bool _busy = false;
  int _generation = 0;
  Timer? _idleTimer;
  Timer? _reactionTimer;
  int _idlePulse = 0;

  CompanionMood get mood => _mood;
  bool get busy => _busy;
  int get queueLength => _queue.length;
  int get idlePulse => _idlePulse;

  void play(CompanionMood mood, {Duration? duration}) {
    _queue.add(
      CompanionReaction(
        mood: mood,
        duration: duration ?? _defaultDuration(mood),
      ),
    );
    notifyListeners();
    _drain();
  }

  /// Clear pending reactions and stop the current one (Yofardev interrupt idea).
  void interrupt({CompanionMood returnTo = CompanionMood.idle}) {
    _generation++;
    _queue.clear();
    _reactionTimer?.cancel();
    _busy = false;
    _mood = returnTo;
    notifyListeners();
  }

  Duration _defaultDuration(CompanionMood mood) {
    switch (mood) {
      case CompanionMood.thinking:
        return const Duration(milliseconds: 2200);
      case CompanionMood.celebrate:
        return const Duration(milliseconds: 2000);
      case CompanionMood.wave:
        return const Duration(milliseconds: 1400);
      default:
        return const Duration(milliseconds: 1600);
    }
  }

  Future<void> _drain() async {
    if (_busy) return;
    _busy = true;
    final gen = _generation;

    while (_queue.isNotEmpty && gen == _generation) {
      final next = _queue.removeFirst();
      _mood = next.mood;
      notifyListeners();

      final done = Completer<void>();
      _reactionTimer?.cancel();
      _reactionTimer = Timer(next.duration, done.complete);
      await done.future;
      if (gen != _generation) return;
    }

    if (gen == _generation) {
      _mood = CompanionMood.idle;
      _busy = false;
      notifyListeners();
    }
  }

  void _scheduleIdlePulse() {
    _idleTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (_mood == CompanionMood.idle) {
        _idlePulse++;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _reactionTimer?.cancel();
    super.dispose();
  }
}
