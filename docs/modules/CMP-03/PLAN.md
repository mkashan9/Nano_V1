# CMP-03 plan

1. Add `CompanionPlacement` and the surface × experience table to `nano_domain`,
   with the Junior-is-never-quieter invariant as a test rather than a comment.
2. Add `CompanionController` to the design system: session-scoped owner of
   `CompanionRuntime`, injectable clock, surface entry, dismissal, preference
   updates, resume handling, and session reset.
3. Expose it through `NanoCompanionScope` and add `CompanionSurfaceStage` so a
   screen declares its surface and arrival moment and nothing else.
4. Move sizing into `CompanionStage.artSizeFor(placement, prominent, storyCard)`
   so no page passes a hand-picked number.
5. Wire the student app: one controller in `main.dart`, kept in step with
   preferences and experience, plus a lifecycle hook for coming back.
6. Place the companion on Junior home, Senior home, the topic player (start and
   completion), and the progress empty state.
7. Tests: placement table, session continuity and budget, one-companion-at-a-time,
   resume rules, Classroom Mode, and the student-app placements.
8. Document decisions and the owner manual test; update status files.
