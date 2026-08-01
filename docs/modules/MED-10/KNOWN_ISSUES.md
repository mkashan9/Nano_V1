# MED-10 known issues

**No eye blink.** The module name promised one and there is none. A blink needs
a second eye state, and over a flat JPEG every way of getting one is worse than
going without: generated eyes-closed variants cannot be relied on to register
pixel-for-pixel so a cross-fade reads as a glitch; a procedural eyelid needs
hardcoded eye coordinates that go wrong the first time a pose is regenerated;
and squashing the whole character is not a blink. The correct fix is art
authored in layers with the eyes separate, which is content work. See
DECISIONS.

**Nori does not gesture.** She breathes, drifts, and tilts. She does not wave,
point, or jump — the pointing pose points because it was drawn pointing, not
because anything animates the arm. Real gesture is a clip.

**The motion does not respond to anything.** It is a loop, not a reaction. Nori
does not look toward a tap, follow a scroll, or settle after an entrance. Each
of those is cheap on its own and none is in this module.

**Amplitudes are one size.** The same spec runs on the 72-pixel Senior circle
and the 140-pixel Junior one. It is proportional so it does not break, but a
Senior learner who expects to be left alone arguably deserves less movement
than a six-year-old, and the spec has no way to say so.

**Rest and repeat are not modelled.** Real idle animation has beats — a pause,
a shift, a longer pause. This is continuous sine motion, which is calm but
slightly mechanical if you stare at it. Adding phase-randomised rest gaps would
help and would also make the motion untestable by exact comparison, so it was
left out.

**The test switch is global mutable state.** `debugAmbientMotionEnabled` is a
static. Two test files mutating it in parallel would interfere; Dart test runs
files in separate isolates so today they cannot, but the hazard is real if that
ever changes.
