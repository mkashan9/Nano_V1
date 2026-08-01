import 'package:nano_domain/nano_domain.dart';

/// How a mood moves when nothing is being generated for it (MED-10).
///
/// Tier 1 of the handbook's asset ladder is bundled and reusable motion. It is
/// the tier that makes a companion feel alive, and it is the only tier that
/// costs nothing to run: no render spend, no network, no file to fetch, nothing
/// that can fail in a classroom with bad wifi.
///
/// Everything here is a small periodic offset applied to art that already
/// exists. That constraint is what keeps the motion honest — it cannot invent a
/// gesture the drawing does not have, so it can only ever add the difference
/// between a picture and a living thing, which is mostly breathing.
///
/// Amplitudes are deliberately small. A companion that moves enough to notice
/// is a companion competing with the lesson.
class CompanionMotionSpec {
  const CompanionMotionSpec({
    required this.breathPeriod,
    required this.breathScale,
    this.bobPeriod = const Duration(seconds: 5),
    this.bobFraction = 0,
    this.swayPeriod = const Duration(seconds: 7),
    this.swayTurns = 0,
  });

  /// One full inhale and exhale.
  final Duration breathPeriod;

  /// How much bigger the character gets at the top of a breath, as a fraction
  /// of its size. 0.02 is two percent and is already near the top of what reads
  /// as breathing rather than pulsing.
  final double breathScale;

  /// A slow vertical drift, deliberately out of step with the breath so the two
  /// together never land on an obviously mechanical beat.
  final Duration bobPeriod;
  final double bobFraction;

  /// A slight rotation, which reads as a head tilt on a character whose head
  /// and body are one shape.
  final Duration swayPeriod;
  final double swayTurns;

  /// Whether this spec would move anything at all.
  bool get isStill => breathScale == 0 && bobFraction == 0 && swayTurns == 0;

  /// The largest fraction of the frame the character can be displaced by, used
  /// to pre-scale the art so motion never drags an empty edge into the circle.
  double get maxExcursion => breathScale + bobFraction + swayTurns.abs() * 2;

  /// The motion signature for a mood.
  ///
  /// Every mood has one, at every tier. The asset ladder describes what the app
  /// has to *fetch* — a bundled pose, an approved picture, a rendered clip —
  /// and motion over a still costs nothing to fetch, so there is no rung where
  /// withholding it would save anything. What the tier still decides is whether
  /// a clip may ever replace the still, which is a curation question and stays
  /// where MED-08 left it.
  ///
  /// Each signature is chosen to read as its mood with the sound off and the
  /// caption covered, because that is the test that matters: motion that needs
  /// a label to be understood is decoration.
  static CompanionMotionSpec forMood(CompanionMood mood) => switch (mood) {
        // Calm and slow. Idle is the mood that is on screen longest, so it is
        // the one most able to become annoying.
        CompanionMood.idle => const CompanionMotionSpec(
            breathPeriod: Duration(milliseconds: 4400),
            breathScale: 0.014,
            bobPeriod: Duration(milliseconds: 6300),
            bobFraction: 0.008,
          ),
        // A little lift, as though just arrived.
        CompanionMood.greeting => const CompanionMotionSpec(
            breathPeriod: Duration(milliseconds: 3200),
            breathScale: 0.018,
            bobPeriod: Duration(milliseconds: 4100),
            bobFraction: 0.014,
            swayPeriod: Duration(milliseconds: 5300),
            swayTurns: 0.005,
          ),
        // Leaning in toward whatever is being shown, with a quicker pulse than
        // rest so it reads as attention rather than calm.
        CompanionMood.point => const CompanionMotionSpec(
            breathPeriod: Duration(milliseconds: 2900),
            breathScale: 0.016,
            bobPeriod: Duration(milliseconds: 3700),
            bobFraction: 0.012,
            swayPeriod: Duration(milliseconds: 6700),
            swayTurns: 0.004,
          ),
        // The widest sway of the set: on a character whose head and body are
        // one shape, a slow tilt from side to side is the whole vocabulary of
        // pondering.
        CompanionMood.thinking => const CompanionMotionSpec(
            breathPeriod: Duration(milliseconds: 4600),
            breathScale: 0.011,
            bobPeriod: Duration(milliseconds: 7900),
            bobFraction: 0.005,
            swayPeriod: Duration(milliseconds: 4900),
            swayTurns: 0.011,
          ),
        // A slow nod, nothing else. Anything springy here would read as
        // cheerfulness at a child who just got something wrong.
        CompanionMood.gentleRetry => const CompanionMotionSpec(
            breathPeriod: Duration(milliseconds: 3900),
            breathScale: 0.013,
            bobPeriod: Duration(milliseconds: 4300),
            bobFraction: 0.015,
          ),
        // The one place a bigger movement is right, and still under four
        // percent: this fires after a correct answer, not continuously.
        CompanionMood.celebration => const CompanionMotionSpec(
            breathPeriod: Duration(milliseconds: 2000),
            breathScale: 0.030,
            bobPeriod: Duration(milliseconds: 1500),
            bobFraction: 0.024,
            swayPeriod: Duration(milliseconds: 2300),
            swayTurns: 0.009,
          ),
      };
}
