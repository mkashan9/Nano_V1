# MED-02 test report

Date: 2026-08-01

## Database (development project `nano_v1`)

| Check | How | Result |
|-------|-----|--------|
| MCP `apply_migration med02_quotas_caching_fallback` | Supabase MCP | success on the second attempt; the first failed because an enum cast is not immutable and so cannot sit in an index expression (see below) |
| A new ask is counted, an identical one is not | `execute_sql`, superadmin JWT | one request charged to the platform budget and one to the companion budget; the reused ask left both unchanged |
| A spent budget refuses before a provider is reached | `execute_sql` | `NM006` naming the platform budget; no `generated_assets` row created |
| One spent budget is not an outage | `execute_sql` | with `video` at zero, an image request still succeeded |
| A feature budget stops that feature only | `execute_sql` | `companion` at zero refused; a request for the unbudgeted `onboarding` feature fell back to the platform budget and succeeded |
| Cost is charged when known, and once | `execute_sql`, service role | 2500 micros recorded after the result; the duplicated callback was refused (`NM004`) and the spend stayed 2500 |
| Delivery gate | `execute_sql`, learner JWT | approved file readable; unreviewed file not; unknown path not; the catalog agreed at one row |
| Budget visibility | `execute_sql` | admin sees 4 budgets; learner sees 0 rows from `generation_budget_status()`, 0 from `generation_quotas`, 0 from `generation_usage` |
| Budgets are not writable by anyone signed in | `has_table_privilege` | no `update` on `generation_quotas`, no `insert` on `generation_usage` |
| Nothing left behind | `execute_sql` | 0 assets, 0 usage rows, and the 4 seeded budgets after every block rolled back |
| Security advisors | MCP `get_advisors` | no new ERROR; the two new WARNs are the intended signed-in RPCs (`request_generated_asset`, `generation_budget_status`), both of which check `is_platform_admin` internally |

The full script is `supabase/tests/med02_quotas_caching_fallback.sql`, run in blocks
through MCP `execute_sql`, each block inside a transaction that rolled back.

Two things the tests changed about the code:

- The unique index over `(scope, scope_key, kind)` originally used
  `coalesce(kind::text, '*')`, which PostgreSQL rejects because an enum cast is
  not immutable. It is now `nulls not distinct`, which says the same thing
  directly.
- The first draft of the SQL suite changed a budget while acting as
  `authenticated` and was refused. That refusal is correct, so the suite now
  changes budgets before switching role, and asserts the missing grant explicitly.

## Dart

| Suite | Command | Result |
|-------|---------|--------|
| Domain | `dart test packages/nano_domain` | 212 passed (6 new: budget parsing, exhaustion, late-arriving clips) |
| Data | `dart test packages/nano_data` | 82 passed (3 new: quota refusal, budget reporting, budget dimensions) |
| nano_media | `dart test packages/nano_media` | 18 passed (9 new: TTL, shared fetch, last-known-good, URL reuse and re-signing, fallback reasons) |
| Design system | `flutter test packages/nano_design_system` | 41 passed |
| Student app | `flutter test apps/student_app` | 116 passed (3 new: availability wiring, published clip picked up, failing catalog is invisible) |
| Teacher app | `flutter test apps/teacher_app` | 2 passed |
| Admin web | `flutter test apps/admin_web` | 13 passed |
| Static analysis | `dart analyze packages/nano_domain packages/nano_data packages/nano_media packages/nano_design_system apps/student_app` | 13 pre-existing issues, none in files this module touched |

### New coverage worth naming

- **A spent budget still reuses.** The fake repository enforces its own daily
  limit, and the test asserts that after the limit is reached a *new* slot is
  refused while an *existing* one is still returned. That is the ordering rule in
  the database, checked again in the layer that talks to it.
- **One fetch per TTL, and one fetch for three simultaneous callers.** Both are
  asserted through a counter rather than a mock expectation, so the test says what
  it costs rather than how it was called.
- **A failure is indistinguishable from empty.** Two tests: a failure after a
  success keeps the last catalog, and a failure on a first run gives an empty one.
  Neither throws.
- **A regenerated file is signed again.** After a refresh replaces the file, the
  cached URL count drops to zero and the new checksum is signed.
- **The app does not care.** The widget test runs the real app with a repository
  that always fails, then with one that publishes a clip, and checks
  `clipsAvailable` and that no exception reached the framework.

## Not run

| Test | Why |
|------|-----|
| `supabase/functions/generate-asset/adapters/adapters_test.ts` | No Deno runtime on this machine. MED-02 changed `index.ts` (feature passthrough, `QUOTA_EXCEEDED`, cache headers) but no adapter, so the file is unchanged from MED-01 and still unexecuted. |
| End-to-end generation through `generate-asset` | The function is not deployed; deploying it and setting provider secrets both need owner approval (ADR-0002). The budget rules are enforced in the database, so they apply the moment it is. |
| Real signed-URL delivery from the bucket | Nothing is approved yet, so there is no published file to fetch. The policy is verified through `asset_object_is_published` against seeded approved and unapproved rows. |
