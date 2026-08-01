# MED-06 plan

1. Mark MED-05 DONE, open `module/MED-06-fish-audio-json2video`.
2. Add provider rows and the Fish stock voice; flip defaults; keep Gemini disabled.
3. Add `motion` and the approved-art gate; author `reaction_clip_composition`.
4. Write Fish and json2video adapters against the real API contracts.
5. Wire the compose path into `generate-asset`; keep Gemini adapters registered.
6. Adversarial SQL: unapproved art, wrong shape, permissions, budgets, motion.
7. Deno adapter tests (install Deno locally if needed); Dart default updates.
8. Deploy `generate-asset`; leave keys unset so fail-closed is the live state.
9. Document, STATUS → USER_TEST, open the PR.
