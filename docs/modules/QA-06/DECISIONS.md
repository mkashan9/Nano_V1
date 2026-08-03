# QA-06 — Decisions

1. **Gate aggregation, not a second smoke suite.** Prior QA modules remain
   authoritative; this page records their DONE readiness.
2. **Superadmin Pilot nav.** Uses `platform.audit` permission alongside Security.
3. **Production warns.** Pointing the client at production is a warn, not an
   automatic fail — owner must approve pilot traffic.
4. **Fake-first ops drills.** Backup/support/RLS flags default true for the
   executable checklist; owner confirms against handbook 13.4 / 16.x.
5. **No Docker / no remote deploy.** Checklist does not authorize production
   migration apply.
