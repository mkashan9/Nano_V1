# PROJECT_STATUS

## Current state

- **Current release:** R4 Companion
- **Current module:** MED-03 Voice Generation and Aoede Learning Guide
- **Current status:** USER_TEST
- **Current branch:** module/MED-03-voice-aoede-guide
- **Last completed module:** MED-02
- **Application name:** Nano

## Releases

- R1 Identity: complete
- R2 Student Core: complete (STU-03 through STU-05 DONE)
- R3 Learning: complete (LRN-01–LRN-05, QZ-01–QZ-06 DONE)
- R4 Companion: CMP-01–CMP-03 and MED-01–MED-02 DONE; MED-03 in USER_TEST

## Owner decision waiting

`generate-asset` is still committed and undeployed. MED-03 added a real Aoede
voice adapter and a narration request path; setting `VOICE_PROVIDER_API_KEY` and
deploying both need your approval per `docs/setup/ENVIRONMENTS.md`. Until then
every companion line is a caption, which is the intended resting state.

## Next after MED-03 DONE

MED-04 Video Generation and Reusable Reaction Library: short celebration clips
that reuse the same budget, hash, and approval path, still optional against
local companion art.
