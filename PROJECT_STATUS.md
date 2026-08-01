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

Paste `VOICE_PROVIDER_API_KEY` (Fish Audio) and `VIDEO_PROVIDER_API_KEY`
(json2video) into Supabase Edge Function secrets, then run the MED-06 manual
test. Neither key is in git and neither must ever be. Until they are set, every
voice and every clip fails closed with `PROVIDER_UNCONFIGURED` — captions and
local art keep working.

A curated `guide_greeting_staticArt` picture is waiting in Moderation,
`unreviewed`. A clip of that reaction will refuse with `NM011` until a reviewer
approves it; that is the compose gate working. The generated picture that
preceded it is `rejected`, with the owner's reason recorded.

**Nano has no usable image provider.** Pollinations serves only `sana` to
callers without a token, and it cannot draw a mascot — eleven prompts across
three art directions produced nothing approvable, including a photograph of a
child. Buying an image provider that can draw is an open owner decision; the
adapter would be small. Until then `pollinations_image` stays the default and
companion art comes in by hand through `register_curated_asset`.

## Next after MED-06 DONE

R5 (XP-01) and ADM-01 stay available. ADM-01 should absorb the borrowed
Moderation destination rather than replace it, and is the natural home for a
curated-upload screen — today a curated picture is registered by calling the
RPC, with no admin UI behind it. Picking a specific Fish `reference_id` is a
small follow-up row once the owner chooses a voice.
