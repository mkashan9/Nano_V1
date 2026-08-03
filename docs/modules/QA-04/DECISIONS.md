# QA-04 — Decisions

1. **Executable smoke, not a scanner.** Checks encode contract gates with
   fake flags where UI inspection is owner-manual.
2. **Domain budgets mirror theme floors.** Junior 56 / senior 48 / admin 44 —
   a widget test asserts they stay aligned with `NanoTheme`.
3. **textScale 1.3 smoke.** Same pilot target as QA-02; below-smoke in-range
   is warn, out-of-range is fail.
4. **QA-05 owns bidi.** This module records a pointer check only.
5. **Reuse FND-07 settings.** Audit page links to Accessibility settings for
   reduced motion / captions / Classroom Mode.
