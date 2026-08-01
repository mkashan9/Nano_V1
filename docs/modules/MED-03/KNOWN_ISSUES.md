# MED-03 known issues

## Not run

| Item | Why |
|------|-----|
| `supabase/functions/generate-asset/adapters/gemini_voice_test.ts` | No Deno runtime on the development machine. The adapter is written and registered; run once Deno is available or in CI. |
| End-to-end recording through `generate-asset` | Function not deployed; `VOICE_PROVIDER_API_KEY` not set. Both need owner approval (ADR-0002). Database request path and budgets are verified without calling the provider. |
| Real Listen playback in the student app | No audio plugin yet. `NanoVoicePlayer` is the seam; `voicePlayer` is not passed in `main.dart`, so Listen never appears. Captions work. |

## Pre-existing advisor noise

Security advisors still report `learner_quiz` / `learner_quiz_history` as
SECURITY DEFINER views (from QZ). New WARNs for narration RPCs match the
existing pattern: callable by `authenticated`, gated inside by
`is_platform_admin` (authoring/request) or by RLS-safe published read
(`list_narration_lines`).

## Local vs remote migration filenames

Applied on `nano_v1` as three MCP migrations (`med03_voice_narration_voices`,
`_lines`, `_rpcs`). The git source of truth is the consolidated
`supabase/migrations/20260801160000_med03_voice_narration.sql`, same pattern as
MED-02.
