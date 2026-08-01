# MED-05 plan

1. Module spec, allowed paths, and the ADM-01 dependency note
2. Review columns, append-only `asset_review_events`, reviewer storage policy
3. `apply_asset_review` + batch and single review RPCs
4. Review queue, history, and rejected-rows-are-not-reuse
5. Deterministic history order (`seq`)
6. Adversarial SQL on `nano_v1`
7. Domain models and `AssetReviewRepository` (fake + Supabase)
8. Review strings in both languages
9. Moderation screen on the existing superadmin shell
10. Dart unit and widget tests
11. Docs, status, PR → USER_TEST
