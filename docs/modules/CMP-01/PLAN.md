# CMP-01 plan

1. Domain: closed event set, six core moods, the local script book, the asset
   ladder manifest, and the resolved reaction shape.
2. Domain: the runtime — pure `notify(event, now:, seed:)` with junior/senior
   policy, cooldowns, essential bypass, and accessibility resolution.
3. Design system: `CompanionStage` renders a reaction inside `CompanionSlot`,
   caption bubble sized by prominence.
4. Student app: quiz results react to the server-reported outcome; the component
   gallery shows every reaction for both experiences.
5. Tests: runtime determinism, cooldowns, senior quiet list, accessibility
   fallbacks, empty manifest, plus widget tests on the stage and on results.
6. Docs and status; branch, PR, owner manual test.

No database or Edge Function work: the acceptance gate is that the companion
runs entirely locally.
