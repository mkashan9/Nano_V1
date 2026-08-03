# PAR-03 — Decisions

1. **Child-issued invite.** Learner creates a short code; guardian accepts it.
   There is no guardian discovery of unlinked children.
2. **Fake-first.** In-memory invites/links only; live `guardian_links` deferred.
3. **Demo accept on Me.** Without a guardian app, **Demo: accept as guardian**
   simulates accept with `guardian-demo` so the owner can exercise the loop.
4. **Reuse PAR-01 access.** `GuardianLinkRecord.toChildLink()` feeds
   `GuardianAccessPolicy`; revoke removes active access.
5. **One open invite.** Creating a new invite revokes the previous open code.
