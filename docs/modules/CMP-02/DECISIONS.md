# CMP-02 decisions

- **Mode and mood are separate axes.** The surface picks the mode (which Nori is
  on screen) and the event picks the mood (what Nori is doing). Collapsing them
  would mean every celebration became Celebration Nori, so a quiz pass would
  read like a level-up. Keeping them apart is what makes "Quiz Coach Nori,
  celebrating" expressible.

- **Modes share the script book.** A mode changes accent, emblem, and framing —
  never the wording or the narration style. This is the handbook's "controlled
  variation, not random inconsistency" rule made structural: there is no place to
  put mode-specific prose, so a variant cannot contradict the guidance.

- **The mode is named, not just coloured.** Every reaction carries a badge
  ("Nori · Quiz coach"), which keeps the variant legible for a learner who cannot
  distinguish the accents and satisfies the "colour is never the only indicator"
  contract.

- **Story cards are chosen by rule, not by the caller.** `CompanionRules`
  decides that only the onboarding welcome, a new world, and a level milestone
  earn the framed treatment. A screen cannot promote its own moment into an
  interruption.

- **Priority is a small closed ladder.** Essential 100, story card 80, guidance
  50, idle 10, with ties resolved by the caller's order. A stable tie-break
  matters more than a clever one: the same collision must produce the same
  reaction every time, which is the CMP-01 determinism rule extended to
  collisions.

- **Classroom Mode holds back ordinary guidance entirely.** CMP-01 only removed
  the voice and the motion. The handbook says Classroom Mode "suppresses
  non-essential interruptions", so CMP-02 makes it a suppression rule and keeps
  the essential outcome path intact. The CMP-01 test that asserted a muted
  greeting now asserts the muted *outcome*, which is the behaviour that actually
  needs protecting.

- **Held-back moments do not spend the budget.** Otherwise a Classroom Mode
  session would exhaust its allowance on reactions the learner never saw, and the
  first real moment after class would be silently dropped.

- **Suppression returns a reason.** `skipReason` distinguishes quiet-for-senior,
  cooldown, Classroom Mode, and spent budget. A silent no-op is untestable and
  impossible to debug from a bug report.

- **The onboarding welcome reads the learner's own preferences.** During
  onboarding the accessibility settings are being *set*, so the flow's own
  `StudentPreferences` is the authority there rather than the app-level scope.
