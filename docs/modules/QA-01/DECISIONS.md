# QA-01 — Decisions

1. **Executable checklist.** Hardening is a report of pass/fail gates, not a
   prose-only audit.
2. **Reuse `/audit` nav.** Existing superadmin Audit destination becomes the
   Security hardening surface (label: Security).
3. **Anon-only clients.** Flutter may only carry publishable anon material;
   `service_role` in `SUPABASE_ANON_KEY` throws.
4. **Server authority unchanged.** Checklist item documents that client guards
   are advisory; SEC-02/SEC-03 RLS decides.
5. **No secret scanning of disk.** Pattern policy is for strings/tests; local
   ignore rules remain the commit boundary.
