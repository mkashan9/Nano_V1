# PAR-02 — Decisions

1. **Fake-first PDF.** Attach stores a filename ending in `.pdf`, not a
   binary upload or storage bucket. Live media is deferred.
2. **Publish gate.** `WeeklyGuidancePublishPolicy` requires title, body,
   week key, and PDF name before status becomes published.
3. **Admin-only surface.** Superadmin permission `platform.parentGuidance`;
   school admins do not see the destination.
4. **PAR-01 mapping.** `toParentGuidanceCard()` converts a published package
   into the learner/guardian card shape; student repo sync is out of scope.
5. **Reuse.** Extends PAR-01 card fields; does not invent a second tip model.
