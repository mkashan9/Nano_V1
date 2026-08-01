# CMP-01 decisions

- **The runtime is pure and immutable.** `notify` takes `now` and a `seed`
  instead of reading a clock or a random source, and returns a new runtime. That
  is the whole reason "reaction selection is deterministic for tests" holds, and
  it lets a stateless widget derive a reaction from data it already has (the quiz
  results screen seeds with `attemptNumber` and times with `scoredAt`).

- **A closed event set, not free text.** Surfaces name a moment; the script book
  owns the words. A new line or a translation lands in one file rather than in
  every screen, and the companion cannot drift into inventing feedback.

- **The companion is told the outcome, never asked to work it out.**
  `CompanionEvent.forOutcome(passed:)` takes a server-authored boolean. There is
  no arithmetic anywhere in the runtime, which keeps the handbook rule ("Nori
  never calculates marks, score, XP, rank, or eligibility") structurally true
  rather than a convention.

- **Density is a policy, not a per-screen decision.** `CompanionPolicy.junior`
  and `.senior` hold the cooldown, the prominence, and the list of moments the
  experience ignores. Senior quietness is therefore testable in one place, and a
  screen that notifies about every navigation still produces nothing for Senior.

- **Cooldown history survives dismissal.** `dismiss()` clears the visible
  reaction but keeps `lastShownAt`, so closing a prompt cannot be used to make it
  reappear immediately.

- **Captions are the fallback, not an extra.** Sound off or Classroom Mode
  removes the voice and leaves the caption; captions off leaves the art. The line
  is never lost and the layout never jumps, because everything renders inside the
  fixed-size `CompanionSlot`.

- **The asset ladder resolves downward, never outward.** A mood whose best tier
  is a clip falls back to a local tier unless `clipsAvailable` is explicitly
  true, and an unknown mood resolves to static art. Nothing in this module can
  block on a remote asset, which is the acceptance gate.

- **Placeholder art, real tiers.** `CompanionStage` draws a mood icon until
  MED-01 supplies files, but the resolved tier travels with the widget in
  `assetKey`, so wiring real assets later is a swap inside one widget and the
  goldens have a stable key today.
