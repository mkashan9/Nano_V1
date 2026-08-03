# PAR-01 — Decisions

1. **Student Me is the first surface.** There is no guardian app yet; the
   weekly card is readable from the learner profile so families can review it
   together.
2. **Safety by field denylist.** `ParentGuidanceSafety.forbiddenFieldNames`
   blocks draft marks, private notes, contact, and payment keys.
3. **Guardian access is link-gated.** `loadCardForGuardian` throws when the
   child is not linked — discovery of unlinked children is forbidden.
4. **PDF upload deferred.** PAR-02 owns platform weekly PDF/activity upload;
   this module consumes a published card shape only.
5. **Fake-first links.** PAR-03 will own verified guardian linking; the fake
   seeds one linked pair for policy tests.
