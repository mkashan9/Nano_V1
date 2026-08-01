# PROJECT_STATUS

## Current state

- **Current release:** R4 Companion
- **Current module:** MED-01 Generated Asset Provider Adapters
- **Current status:** USER_TEST
- **Current branch:** module/MED-01-generated-asset-adapters
- **Last completed module:** CMP-03
- **Application name:** Nano

## Releases

- R1 Identity: complete
- R2 Student Core: complete (STU-03 through STU-05 DONE)
- R3 Learning: complete (LRN-01–LRN-05, QZ-01–QZ-06 DONE)
- R4 Companion: CMP-01–CMP-03 DONE; MED-01 in USER_TEST

## Owner decision waiting

MED-01 committed the first Edge Function (`generate-asset`) but did not deploy it,
and set no provider secrets — both need your approval per
`docs/setup/ENVIRONMENTS.md`. The image adapter needs no key, so approving a
development deployment is enough to generate a real picture end to end.

## Next after MED-01 DONE

MED-02 Asset Caching, Hashing, Quotas, and Fallback: per-day and per-school
budgets, cached delivery through signed URLs, and loading the published catalog
into the app so `clipsAvailable` can finally be true.
