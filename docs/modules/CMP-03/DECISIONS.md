# CMP-03 decisions

## The session owns the runtime, not the screen

`CompanionRuntime` stays pure and immutable, so something has to hold the current
one. A `CompanionController` above the router does it, which is why a cooldown
still applies after a route change and a spent budget stays spent. A per-screen
holder would have made every rule from CMP-02 resettable by navigating, which is
the same as not having the rules.

## The controller is the only thing that reads a clock

Every companion decision depends on time, and none of it should depend on the
real one during a test. The runtime takes `now` as an argument; the controller
takes a `clock` callback that defaults to `DateTime.now`. Session behaviour over
hours is therefore an ordinary unit test.

## Placement is a table, not a per-screen judgement

Screens were passing sizes by eye (56, 72, 96), which is how two Junior screens
end up with different companions. `CompanionPlacementPolicy` resolves surface ×
experience to one of four placements, and the design system maps placement to
art size. A screen can still override the size, but it no longer has to choose.

`hidden` is a real placement rather than "just don't add the widget", so the
absence is stated in the same table as the presence and is covered by tests.

## One companion at a time

With a shared controller, two mounted surfaces would both read the same reaction.
`CompanionSurfaceStage` renders only while its surface is the current one, so the
screen the learner is looking at is the one that speaks, and a page behind a
pushed route neither shows a stale line nor competes for attention.

## The gap belongs to the companion

Classroom Mode and the quiet lists mean a stage often renders nothing. If a page
also reserved spacing, turning Classroom Mode on would still shift the layout.
The stage carries its own bottom spacing and collapses completely, so a
held-back reaction costs no height at all.

## Quiz results stay derived, not reported

A result reaction is computed from the server's outcome and the attempt number,
so it is identical every time that result is shown and cannot be changed by how
much a learner saw earlier in the session. Pushing results through the session
controller would have made a celebration depend on session history — and the
result screen is exactly where that must not happen.

## Senior home stays quiet on arrival

Ordinary navigation is on Senior's quiet list (CMP-01), so the Senior home stage
shows nothing on a normal visit. That is the intended behaviour, not a gap: the
placement is there for the moments Senior does accept — returning after a long
absence, and milestones. A test asserts both halves so a future change to the
quiet list cannot silently start greeting Senior learners every visit.

## Thirty minutes is the line for "coming back"

Switching to another app for a moment is not an absence worth commenting on.
Thirty minutes is long enough that a greeting reads as welcome rather than as the
app forgetting the learner never left. The gap is a controller field, so it can
be tuned without touching the runtime.
