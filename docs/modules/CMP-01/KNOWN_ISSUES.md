# CMP-01 known issues

- Art is a mood icon inside the companion circle. Real master art, animation, and
  the Aoede voice arrive with MED-01; `speaks` is currently a resolved intent
  with no audio behind it.
- Only the quiz results moment is wired into a learner surface. Home, learning
  entry, video start/completion, achievements, level-up, missions, and return
  from inactivity are supported by the runtime but still render the plain
  `CompanionSlot`.
- Cooldowns live in the runtime instance a surface holds, so they do not persist
  across a route change or an app restart. A shared app-level holder belongs with
  the wider companion wiring.
- The script book has one or two lines per mood. It reads as intentional
  repetition today; more variants and Urdu review are content work.
- `companion_events` telemetry (which moment fired, was it dismissed) is not
  recorded anywhere yet.
