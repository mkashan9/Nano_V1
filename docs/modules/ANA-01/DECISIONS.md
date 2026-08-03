# ANA-01 — Decisions

1. **Reuse ADM-08 / SCH-07 surfaces.** Health and taxonomy extend existing
   hubs instead of adding new nav destinations.
2. **Documented taxonomy only.** Events must answer a product/ops question;
   unknown names are rejected by `AnalyticsEventTaxonomy.isKnown`.
3. **Traceable score.** `SchoolHealthMath` weights attendance 40%, assessment
   30%, learning 30%, then subtracts coverage and incident penalties.
4. **Privacy gate.** Payloads still pass `PlatformDashboard.isPrivacySafePayload`
   (no email/marks/user ids).
5. **Fake-first.** No live warehouse; failure must not block learning paths.
6. **School-scoped load.** School reports health uses that school's id only.
