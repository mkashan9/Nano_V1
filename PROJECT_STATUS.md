# PROJECT_STATUS

## Current state

- **Current release:** R4 Companion
- **Current module:** MED-07 Wan 2.2 Character Animation with Compose Fallback
- **Current status:** USER_TEST
- **Current branch:** module/MED-07-wan-character-animation
- **Last completed module:** MED-06
- **Application name:** Nano

## Releases

- R1 Identity: complete
- R2 Student Core: complete (STU-03 through STU-05 DONE)
- R3 Learning: complete (LRN-01–LRN-05, QZ-01–QZ-06 DONE)
- R4 Companion: CMP-01–CMP-03 and MED-01–MED-06 DONE; MED-07 in USER_TEST

## Owner decision waiting

Open admin_web → Moderation and decide the Wan clip waiting there:

1. `guide_greeting_shortClip` (MP4, `provider_id = wan_i2v_space`, provenance
   shows `motion = driftIn` and the approved picture it was made from)

Approving publishes it. Rejecting frees the slot. Until you decide it stays
invisible — that is MED-05 working.

The live Wan render against `nano_v1` has already passed (~27s warm, 164 KB,
Nori waves). The compose gate (`NM011` without approved art) and the one-hop
fallback to json2video are covered by automated tests; the fallback path can
also be exercised manually by pointing `VIDEO_SPACE_URL` at a dead host.

## What a learner can actually see and hear

Still nothing generated reaches a child: no player exists outside admin_web.
Approved media sits in the catalog. Every companion moment in the student app
is a caption over local art.

## Content coverage

| Surface | Authored | Approved |
|---------|----------|----------|
| Narration lines | 6 slugs × en/ur | 1 (`greeting-2` en) |
| Reaction clips | 3 slugs | 0 (one Wan clip waiting) |
| Companion art | 1 slot | 1 (`guide_greeting` 1:1) |

## Next after MED-07 DONE

A learner-facing player module is the highest-value remaining gap in R4 — without
it no approved voice or clip reaches a child. XP-01 is also eligible (its only
dependencies finished in R0/R1). ADM-01 should absorb the borrowed Moderation
destination and is the natural home for a curated-upload screen.
