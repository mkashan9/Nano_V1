# XP-01 test report

## Automated

| Suite | Result |
|-------|--------|
| `packages/nano_domain` xp_ledger_test | 4 passed |
| `packages/nano_data` xp_ledger_repository_test | 3 passed |

## SQL

`supabase/tests/xp01_ledger_idempotency.sql` — schema probes. Applied migration
live on development; rules seeded (video 10, quiz_pass 30), ledger empty
awaiting learner activity.

## Not covered by automation here

End-to-end award on a real completion/submit against development — that is the
manual test. A full adversarial SQL suite with a learner JWT needs psql to the
dev project.
