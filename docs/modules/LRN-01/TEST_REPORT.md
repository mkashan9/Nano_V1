# LRN-01 Test Report

| Suite | Result |
| --- | --- |
| `packages/nano_domain/test/learning_catalog_test.dart` | PASS |
| `packages/nano_data/test/learning_catalog_repository_test.dart` | PASS |
| `apps/student_app/test/learning_catalog_page_test.dart` | PASS |
| `supabase/tests/lrn01_catalog_visibility.sql` (via MCP) | PASS |

Adversarial SQL confirmed: junior sees Math only with addition locked; senior grade 8 gains Science; grade 2 senior loses Science; drafts stay invisible to learners/teachers; admin preview sees draft Coding; anon sees zero rows; progress cannot be written for another user.
