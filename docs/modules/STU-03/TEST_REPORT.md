# STU-03 — Test report

| Test | Result |
|------|--------|
| `packages/nano_domain/test/student_home_summary_test.dart` | PASS (5 tests) |
| `packages/nano_data/test/student_home_repository_test.dart` | PASS (4 tests) |
| `apps/student_app/test/junior_home_page_test.dart` | PASS (8 tests) |
| `apps/student_app` full suite | PASS (33 tests) |
| `packages/nano_domain` full suite | PASS (44 tests) |
| `packages/nano_data` full suite | PASS (15 tests) |
| `flutter analyze` (domain, data, student_app) | 2 pre-existing issues, none from this module |

## Coverage notes

- Junior rules: mission cap at three, XP total, percent rounding, content check, freshness label thresholds.
- Repository: identity pass-through, cache timestamps, failure then successful retry, notice pass-through.
- Screen states: loaded content, retry recovery, offline banner with timestamp, maintenance block, access-warning banner, missing subjects.
- Shell integration: junior shell renders the continue card and reaches the subject grid by scrolling.

## Not run

- No SQL tests: this module introduces no database objects.
