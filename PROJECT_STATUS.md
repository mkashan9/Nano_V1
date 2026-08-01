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

One asset is waiting in admin_web → Moderation:

1. The re-recorded `narration_greeting-2` (MP3, `provider_id =
   fish_audio_voice`, `voice_id = guide_educational` — Fish Educational Guide,
   the female teacher voice chosen from five candidates)

Approving it publishes that line to learners. Rejecting it frees the slot.
Until you decide, it stays invisible — that is MED-05 working.

Already decided and recorded:

- The curated `guide_greeting_staticArt` picture — **approved**
- The first generated picture — **rejected** (Pollinations `sana` cannot draw)
- The json2video `guide_greeting_shortClip` — **rejected** ("looking very fake";
  character animation moves to MED-07)
- The stock-voice `narration_greeting-2` — **rejected** (ADR-0008: the guide is
  a female teacher, not Fish stock)

## Next after MED-06 DONE

MED-07 Wan 2.2 image-to-video for reaction clips, with json2video kept as an
automatic fallback when the public Space is down. Owner locked the sequence
(finish MED-06 first), the cast voice (Educational Guide), and the hosting
shape (Space as default, json2video as fallback). A live probe against the
approved Nori art already rendered a 3.3-second clip where Nori stays on model
and waves.

R5 (XP-01) and ADM-01 stay available after MED-07. ADM-01 should absorb the
borrowed Moderation destination and is the natural home for a curated-upload
screen — today a curated picture is registered by calling the RPC.
