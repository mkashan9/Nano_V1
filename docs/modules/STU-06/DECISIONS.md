# STU-06 — Decisions

1. **In-app inbox only.** STU-06 owns the student-facing list and mark-read UX.
   Push delivery and deep-link routing from OS notifications stay in NOT-01.
2. **Fake-first repository.** No `inbox_items` table in this module. Fake seed
   unblocks Home entry and owner testing; a Supabase-backed repo waits for the
   notification fan-out schema.
3. **Deep links are hints.** Opening an item marks it read and shows the
   stored path in a snackbar. Full navigation through `DeepLinkResolver`
   lands with NOT-01 once push payloads exist.
4. **Unread badge stays on home summary.** The Home bell badge continues to use
   `StudentHomeSummary.unreadNotifications` until the live inbox can feed it.
5. **ADM-07 templates stay separate.** Template authoring is admin-owned; this
   module only presents items already destined for a learner.
