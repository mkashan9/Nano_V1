# PROJECT_STATUS

## Current state

- **Current release:** R4 Companion
- **Current module:** MED-05 Superadmin Asset Review and Publication
- **Current status:** USER_TEST
- **Current branch:** module/MED-05-asset-review-publication
- **Last completed module:** MED-04
- **Application name:** Nano

## Releases

- R1 Identity: complete
- R2 Student Core: complete (STU-03 through STU-05 DONE)
- R3 Learning: complete (LRN-01–LRN-05, QZ-01–QZ-06 DONE)
- R4 Companion: CMP-01–CMP-03 and MED-01–MED-04 DONE; MED-05 in USER_TEST

## Owner decision waiting

`generate-asset` is **deployed** (owner approved, 2026-08-01). Images work end to
end and cost nothing: one real companion image has been generated and is sitting
unreviewed, ready for the MED-05 manual test.

Voice and video keys have been chosen (Fish Audio and json2video) and validated
live, but they are not set as Edge Function secrets yet and the adapters that
speak those APIs do not exist. That work is MED-06 and waits for MED-05 DONE.
Until then both kinds fail closed with `PROVIDER_UNCONFIGURED`, which is the
correct undeployed state: every caption and every reaction keeps its local art.

MED-05 was also built on the admin shell QZ-01 and QZ-02 shipped, because ADM-01
is still BACKLOG. ADM-01 should absorb the Moderation screen rather than replace
it.

## Next after MED-05 DONE

MED-06 Fish Audio Narration and Composed Reaction Clips. The owner approved a
provider switch after MED-05 was already in USER_TEST and asked that MED-05
finish first:

- Voice moves from Gemini TTS to Fish Audio. The adapter is new; the default
  voice is Fish's stock voice until a `reference_id` is picked.
- Video moves from generative Veo to json2video composing short clips from
  approved Nori art. That is a design change to MED-04's direction field — a
  clip is no longer invented from a prompt, it is motion over art a reviewer
  already signed off.
- Both keys have been validated live and must be pasted into Supabase Edge
  Function secrets by the owner; they are not in git and must never be.

R5 (XP-01) and ADM-01 stay available after MED-06. ADM-01 should still absorb
the borrowed Moderation destination rather than replace it.
