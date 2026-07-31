# STU-04 — Test report

| Test | Result |
|------|--------|
| `packages/nano_domain/test/student_home_summary_test.dart` | PASS (12 tests, 7 new for senior) |
| `packages/nano_data/test/student_home_repository_test.dart` | PASS (6 tests, 2 new) |
| `apps/student_app/test/senior_home_page_test.dart` | PASS (11 tests) |
| `apps/student_app/test/shell_navigation_test.dart` | PASS (2 tests) |
| `apps/student_app` full suite | PASS (45 tests) |
| `packages/nano_domain` full suite | PASS (51 tests) |
| `packages/nano_data` full suite | PASS (17 tests) |
| `flutter analyze` (domain, data, student_app) | 2 pre-existing issues, none from this module |

## Coverage notes

- Level: derivation from XP, remainder and fraction, floor of level 1 for zero or negative XP.
- Senior vs junior: `plan` returns every mission while `juniorMissions` still caps at three.
- Partial data: a failed section marks the summary partial without emptying it; the page shows an inline notice, keeps the rest of the home, and does not show the full error state.
- Section retry re-runs the aggregated read (`loadCount` goes from 1 to 2).
- Flex: absent for ineligible learners, present with counts and due label for eligible ones, hidden when its section fails, and the card invokes the deep-link callback.
- Blocking and notice states: total failure with retry recovery, cached content with timestamp, maintenance block.
- Locale: Urdu plan heading and level line.
- Shell: independent deep link to `/flex` falls back to Home and renders the senior composition.

## Adjusted existing tests

- `shell_navigation_test.dart`: the senior shell now renders a Flex summary card in addition to the Flex nav destination, and independents show the senior composition. Assertions updated accordingly.

## Not run

- No SQL tests: this module introduces no database objects.
