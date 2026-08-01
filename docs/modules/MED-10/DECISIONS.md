# MED-10 decisions

## The tier decides clip eligibility; it does not ration motion

The obvious reading of the ladder is that `staticArt` gets no motion and
`localAnimation` gets some. That was rejected.

The ladder describes what the app has to *fetch* — a bundled pose, an approved
picture, a rendered clip. Motion over a still costs nothing to fetch, so there
is no rung where withholding it would save anything, and there is no rung where
a frozen drawing looks less broken. Every mood therefore gets its signature at
every tier.

What the tier still decides is whether a clip may ever replace the still, which
is a curation question and stays exactly where MED-08 left it. Promoting every
mood's floor to `localAnimation` would have quietly made routine moods
clip-eligible and reversed that decision, so the tier map is untouched.

## One controller, three channels

Breathing, bob, and sway are three sine waves read out of one 60-second
controller at different periods, rather than three controllers. Three tickers
to move two percent of a 96-pixel circle would be three times the bookkeeping
for no visible difference, and the periods are chosen far enough apart that the
combination does not visibly repeat inside a minute.

## The art is pre-scaled

The circular mask has to stay full. Translating or breathing a drawing that
exactly fills the circle would drag an empty crescent into frame, which reads
as a rendering bug rather than as motion. So the art is scaled up by the worst
case of all three channels before any of them is applied, and breath is offset
to run from zero upward rather than symmetrically around zero.

Rotation is free here: a square always contains its own inscribed circle at any
angle, so sway alone can never expose an edge.

## Ambient motion is off by default in tests

This one is a real cost and worth stating plainly.

A perpetual animation means the widget tree never reaches a settled frame, so
`pumpAndSettle` hangs. Twenty-five existing tests across the design system and
the app broke the moment breathing was wired in, none of them because anything
was wrong.

The alternatives were: rewrite those tests to poll fixed durations, which makes
every one of them worse at describing what it is about; or give the motion a
test-only switch. Flutter takes the second route for exactly this class of
problem — `debugDisableShadows`, `timeDilation` — so this does too.
`NoriLivingArt.debugAmbientMotionEnabled` defaults to true, and each package's
`test/flutter_test_config.dart` turns it off once for the whole package.

The two files that are *about* motion turn it back on in `setUp`. Without that
they would pass for the wrong reason: the harness would have stopped the
motion, not the accessibility preference under test.

## No eye blink

The traceability row for this module says "breathing, blink, mood motion", and
there is no blink. This is a deliberate omission rather than an oversight.

A blink needs a second eye state. Over a flat JPEG there are three ways to get
one and all three are bad:

- Generate an eyes-closed variant per pose. Generated frames cannot be relied
  on to register pixel-for-pixel, so cross-fading between them reads as a
  glitch, not a blink — and it doubles the pack and doubles the drift surface
  the MED-09 character sheet exists to control.
- Draw an eyelid shape over the eyes procedurally. That requires knowing where
  the eyes are in each image, which is a hardcoded coordinate that silently
  becomes wrong the first time a pose is regenerated.
- Squash the whole character briefly and call it a blink. It is not a blink.

The correct fix is art authored in layers, with the eyes as a separate element.
That is a content decision, not a code one. Recorded in KNOWN_ISSUES.

## Gentle retry has no sway

Every other mood with meaningful energy got a small rotation. This one is
capped at zero and a test asserts it. A springy, waggling companion in front of
a child who just got an answer wrong is the single worst thing this tier could
do, and it is the kind of thing that arrives later as a one-line "make it more
lively" tweak.
