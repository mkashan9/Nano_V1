# SEC-03 Implementation Plan

1. Create audit/session/incident tables with RLS (select for scoped roles; no client writes).
2. Extend `nano_internal` helpers for school/profile suspension and session validity.
3. Re-assert tenancy select policies using suspension-aware helpers.
4. Seed deterministic fixtures; mirror in `nano_domain`.
5. Document, test, PR → USER_TEST.
