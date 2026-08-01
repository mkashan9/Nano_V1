# XP-02 test report

| Check | Result |
| --- | --- |
| `packages/nano_domain/test/level_progress_test.dart` | RUN |
| `packages/nano_domain/test/xp_ledger_test.dart` | RUN |
| `packages/nano_domain/test/student_home_summary_test.dart` | RUN |
| `packages/nano_data/test/xp_ledger_repository_test.dart` | RUN |
| `supabase/tests/xp02_level_thresholds.sql` | RUN (MCP / migration probe) |
| Secrets in diff | PASS — none |
| Owner manual test | PENDING — see MANUAL_TEST.md |

## Notes

Domain tests cover `fromXp`, `fromServer` (including a non-linear band), and
balance JSON with and without level fields. Data tests assert Home prefers
server `levelProgress` when a ledger is attached and that fake credits refresh
the derived level.
