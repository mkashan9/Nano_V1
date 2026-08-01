# PROJECT_STATUS

## Current state

- **Current release:** R4 Companion
- **Current module:** MED-06 Fish Audio Narration and Composed Reaction Clips
- **Current status:** USER_TEST
- **Current branch:** module/MED-06-fish-audio-json2video
- **Last completed module:** MED-05
- **Application name:** Nano

## Releases

- R1 Identity: complete
- R2 Student Core: complete (STU-03 through STU-05 DONE)
- R3 Learning: complete (LRN-01–LRN-05, QZ-01–QZ-06 DONE)
- R4 Companion: CMP-01–CMP-03 and MED-01–MED-05 DONE; MED-06 in USER_TEST

## Owner decision waiting

Paste nothing — both keys are already set. Open admin_web → Moderation and
decide the two assets waiting there:

1. The composed `guide_greeting_shortClip` (MP4, `provider_id =
   json2video_compose`, provenance shows `motion = driftIn` and the approved
   picture it was made from)
2. The recorded `narration_greeting-2` (MP3, `provider_id = fish_audio_voice`)

Approving either publishes it to learners. Rejecting either frees the slot for
a better attempt. Until you decide, both stay invisible to every learner — that
is MED-05 working.

The live generation and compose steps of this manual test have already been
run against `nano_v1` and passed. The refusal with no approved art
(`celebration_celebration` → `NM011`) was also confirmed.

## Next after MED-06 DONE

R5 (XP-01) and ADM-01 stay available. ADM-01 should absorb the borrowed
Moderation destination rather than replace it, and is the natural home for a
curated-upload screen — today a curated picture is registered by calling the
RPC, with no admin UI behind it. Picking a specific Fish `reference_id` is a
small follow-up row once the owner chooses a voice.
