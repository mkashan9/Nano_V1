import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:nano_domain/nano_domain.dart';

import '../tokens/nano_motion.dart';
import 'companion_motion.dart';

/// Puts breath into a still drawing (MED-10).
///
/// Wraps whatever the art ladder resolved — a published picture, a bundled
/// pose — and applies a small periodic transform. It never draws anything of
/// its own, so it cannot put Nori off model: the worst it can do is move her.
///
/// Three rules hold this together.
///
///   * **Accessibility decides, not the tier.** Motion is gated on
///     [NanoMotion.resolve], which is the one place reduced motion and
///     Classroom Mode are read. A tier table cannot outvote a child's setting.
///   * **Free when unseen.** The ticker comes from [SingleTickerProviderStateMixin],
///     so Flutter's own [TickerMode] mutes it when the companion's route is not
///     current, and a backgrounded app produces no frames to drive it at all.
///     There is no timer to leak and nothing to remember to cancel.
///   * **Never in the way of a tap.** The transform is applied inside the
///     circular mask, beneath the mode ring and the play badge, so the target a
///     learner is aiming at does not move while they aim at it.
class NoriLivingArt extends StatefulWidget {
  const NoriLivingArt({
    super.key,
    required this.mood,
    required this.child,
    this.enabled = true,
  });

  final CompanionMood mood;
  final Widget child;

  /// False while something else owns the frame — a clip that is playing has its
  /// own motion and does not want ours on top of it.
  final bool enabled;

  /// Test-only switch for ambient motion.
  ///
  /// Breathing never stops, which is the point of it and is also fundamentally
  /// incompatible with `pumpAndSettle`: a tree with a perpetual animation never
  /// reaches a settled frame, so every existing widget test that waits for one
  /// would hang. Rather than rewrite a hundred tests to poll fixed durations —
  /// which would make them worse at describing intent — each package turns this
  /// off in `test/flutter_test_config.dart`, and the tests that are *about*
  /// motion turn it back on.
  ///
  /// This is the same shape as Flutter's own `debugDisableShadows`. It is never
  /// touched outside tests, and a release build leaves it true.
  static bool debugAmbientMotionEnabled = true;

  @override
  State<NoriLivingArt> createState() => _NoriLivingArtState();
}

class _NoriLivingArtState extends State<NoriLivingArt>
    with SingleTickerProviderStateMixin {
  /// One long cycle that every channel reads a phase out of.
  ///
  /// A single controller rather than one per channel: three tickers to animate
  /// two percent of a 96-pixel circle would be three times the bookkeeping for
  /// no visible difference, and the periods are prime enough against each other
  /// that they do not visibly repeat inside a minute anyway.
  static const _cycle = Duration(seconds: 60);

  // Built here rather than lazily: a `late` field that is never read under
  // reduced motion would be constructed for the first time inside dispose(),
  // which looks up an inherited widget on an element that is already gone.
  late final AnimationController _controller;

  var _allowed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycle);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Here rather than in build because this is the hook that fires when the
    // accessibility scope or the platform's own animation setting changes, and
    // because starting a ticker during a build is a way to get a frame out of
    // step with the tree it belongs to.
    _sync();
  }

  @override
  void didUpdateWidget(NoriLivingArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _sync();
  }

  /// Run the ticker only when something will actually watch it.
  ///
  /// A repeating controller with no listeners still asks for a frame at every
  /// vsync, which is the whole battery cost of this tier. Stopping it is what
  /// makes "reduced motion" mean free rather than merely invisible.
  void _sync() {
    final allowed = widget.enabled &&
        NoriLivingArt.debugAmbientMotionEnabled &&
        NanoMotion.resolve(context, NanoMotion.normal) != Duration.zero;
    if (allowed == _allowed) return;
    _allowed = allowed;
    if (allowed) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Where in a [period]-long wave we are, as a sine between -1 and 1.
  double _wave(double seconds, Duration period) {
    if (period.inMilliseconds <= 0) return 0;
    final turns = seconds / (period.inMilliseconds / 1000);
    return math.sin(turns * 2 * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    final spec = CompanionMotionSpec.forMood(widget.mood);

    // [_allowed] is false when NanoMotion answered Duration.zero, which is how
    // it says "this learner has asked for stillness". Returning the child
    // untouched is the whole implementation of reduced motion here: no
    // transform, no ticker, no partial version that merely slows down.
    if (!_allowed || spec.isStill) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      // Built once and reused: the picture does not change, only where it sits.
      child: widget.child,
      builder: (context, child) {
        final seconds = _controller.value * _cycle.inSeconds;
        // Breath is offset to sit between 0 and 1 rather than -1 and 1, because
        // shrinking below the resting size would drag the edge of the drawing
        // inside the circular mask and show the surface behind it.
        final breath =
            (_wave(seconds, spec.breathPeriod) + 1) / 2 * spec.breathScale;
        final bob = _wave(seconds, spec.bobPeriod) * spec.bobFraction;
        final sway = _wave(seconds, spec.swayPeriod) * spec.swayTurns;

        // Pre-scaled by the worst case so that no combination of the three
        // channels can pull an empty edge into frame.
        final scale = 1 + spec.maxExcursion + breath;

        return Transform.scale(
          scale: scale,
          // A fraction of the art's own size rather than a pixel count, so the
          // same spec reads identically on the 72-pixel Senior circle and the
          // 140-pixel Junior one.
          child: FractionalTranslation(
            translation: Offset(0, bob),
            child: Transform.rotate(
              angle: sway * 2 * math.pi,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
