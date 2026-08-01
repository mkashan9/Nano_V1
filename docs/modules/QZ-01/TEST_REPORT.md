# QZ-01 test report

## Automated

| Suite | Result |
|-------|--------|
| `packages/nano_domain` `question_bank_test.dart` | 6 passed |
| `packages/nano_data` `question_bank_repository_test.dart` | 5 passed |
| `apps/admin_web` (question bank + existing) | 8 passed |

## Server checks (rolled-back transactions)

| Check | Result |
|-------|--------|
| Learner `questions` count | 0 |
| Admin `question_bank` count | 3 |
| Duplicate stem warning | 1 match |
| Publish succeeds | status `published` |
| Published stem rewrite | refused (`immutable_ok`) |

## Security advisors

Pre-existing `SECURITY DEFINER` RPC warnings remain intentional for auth-gated
authoring. No learner-readable question path was added.
