# LRN-05 test report

## Automated

| Suite | Result |
|-------|--------|
| `packages/nano_domain` (`dart test`) | 118 tests passed (14 new in `learning_insights_test.dart`) |
| `packages/nano_data` (`dart test`) | 50 tests passed (6 new in `learning_insights_repository_test.dart`) |
| `apps/student_app` (`flutter test`) | 87 tests passed (11 new in `learning_progress_page_test.dart`) |
| `flutter analyze` on changed packages | No new issues (3 pre-existing warnings unrelated to this module) |

## Server checks against the development project

Each ran inside a rolled-back transaction as `authenticated` with an explicit
`sub` claim.

| Check | Result |
|-------|--------|
| Fresh junior learner's suggestions | Only `Counting to 20` / `new_subject` |
| Locked topics (`addition`, `plants-and-animals`) suggested | 0 rows |
| Senior-only subject (`science`) visible to a junior | 0 rows |
| Draft subject (`coding`) suggested | 0 rows |
| Summary for a fresh junior | `Math: 0/2, locked=1` |
| After `start_topic` + heartbeat | Same topic, reason becomes `resume` |
| After completion | Recommendation moves to `Adding small numbers` / `next_in_subject` |
| Summary after completion | `Math: 1/2, watched=120` |
| Two unfinished topics, one pushed forward in time | Most recent first: `Ecosystems in depth`, then `Living things` |
| Another learner's `learning_progress` rows readable | 0 rows |
| Another learner's completion counted in my summary | Not counted (`Math: 0 done, watched=0`) |
| Insert into `learning_progress_summary` as a learner | Refused |
| Security advisors after the migration | No new findings; the pre-existing `SECURITY DEFINER` RPC warnings are unchanged |

## Notes

`now()` is frozen inside a transaction, so recency ordering could not be checked
by writing rows in sequence. The test pushes one row's `last_heartbeat_at` forward
by an hour instead, which exercises the same `order by` clause.
