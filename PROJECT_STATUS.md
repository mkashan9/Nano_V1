# PROJECT_STATUS

## Current state

- **Current release:** R4 Companion
- **Current module:** MED-02 Asset Caching, Hashing, Quotas, and Fallback
- **Current status:** USER_TEST
- **Current branch:** module/MED-02-asset-caching-quotas
- **Last completed module:** MED-01
- **Application name:** Nano

## Releases

- R1 Identity: complete
- R2 Student Core: complete (STU-03 through STU-05 DONE)
- R3 Learning: complete (LRN-01–LRN-05, QZ-01–QZ-06 DONE)
- R4 Companion: CMP-01–CMP-03 and MED-01 DONE; MED-02 in USER_TEST

## Owner decision waiting

`generate-asset` is still committed and undeployed, and no provider secret is set
— both need your approval per `docs/setup/ENVIRONMENTS.md`. MED-02 changed the
function (budget dimensions, a `QUOTA_EXCEEDED` answer, long-lived cache headers),
so a deployment now arrives with budgets already enforced in the database. The
image adapter needs no key, so approving a development deployment is enough to
generate a real picture end to end.

## Next after MED-02 DONE

MED-03 Voice Generation and Aoede Learning Guide: choose the voice provider, give
the Learning Guide a real narration path, and keep every spoken line optional
against the captions and local fallback the companion already has.
