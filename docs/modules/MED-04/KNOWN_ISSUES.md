# MED-04 known issues

## Not run

| Item | Why |
|------|-----|
| `gemini_veo_test.ts` | No Deno on this machine |
| End-to-end Veo generation | Function undeployed; no `VIDEO_PROVIDER_API_KEY` (owner approval) |
| Real device video playback | No `video_player` plugin; play badge records intent via the seam |

## Pre-existing advisor noise

`learner_quiz` SECURITY DEFINER views remain from QZ. New WARNs for clip RPCs
match the existing signed-in + internally gated pattern.

## Local vs remote migration filenames

Applied on `nano_v1` as MCP migrations (`med04_video_long_jobs`,
`med04_video_claim_and_progress`, `med04_reaction_clip_library`,
`med04_reaction_clip_rpcs`, `med04_request_reuse_recovery_and_seed`). Git source
of truth is `supabase/migrations/20260801170000_med04_video_reaction_library.sql`.
