# QZ-02 test report

## Automated

| Suite | Result |
|-------|--------|
| `packages/nano_domain` `topic_quiz_test.dart` | 5 passed |
| `packages/nano_data` `topic_quiz_repository_test.dart` | 5 passed |
| `apps/admin_web` `topic_quiz_page_test.dart` | 5 passed |

## Server checks (rolled-back transactions)

| Check | Result |
|-------|--------|
| Learner `learner_quiz` options lack `is_correct` | ok |
| Learner / school staff cannot `create_quiz_draft` | ok |
| Admin publish + title/item rewrite refused | ok |
| Retire keeps history | ok |
| Unpublished question attach refused | ok |

## Security advisors

Pre-existing `SECURITY DEFINER` RPC warnings remain intentional for auth-gated
authoring. Learner projection strips correctness flags.
