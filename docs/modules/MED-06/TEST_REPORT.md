# MED-06 test report

## Automated

| Check | Result |
|-------|--------|
| `supabase/tests/med06_fish_and_json2video.sql` against `nano_v1` | 7/7 sections pass |
| `supabase/tests/med06_curated_companion_art.sql` against `nano_v1` | 4/4 sections pass |
| Deno adapters (`deno test --allow-env`) | **56 passed**, 0 failed |
| Fish Audio adapter | 13 passed |
| json2video compose adapter | 16 passed |
| Prior Gemini adapters (first run on this machine) | 20 passed |
| Shared adapter helpers | 7 passed |
| `deno check` on `generate-asset` | clean |
| Dart workspace (domain, data, media, design, student, teacher, admin) | 583 passed |
| Supabase security advisors | no new ERROR from MED-06 |

## Live

| Check | Result |
|-------|--------|
| Migrations applied on `nano_v1` | `med06_fish_and_json2video_providers`, `med06_composed_reaction_clips`, `med06_compose_gate_and_worker_plan`, `med06_curated_companion_art` |
| Default voice / video providers | `fish_audio_voice`, `json2video_compose` (`composes_from_art = true`) |
| Default narration voice | `guide_fish_stock` / `stock` |
| Seeded motions | `guide_greeting` → `driftIn`, `celebration_celebration` → `pushIn`, `quizCoach_celebration` → `dip` |
| `generate-asset` redeployed | version 3, ACTIVE, `verify_jwt` on |
| Keys as Edge Function secrets | **not set** — fail-closed is the live state until the owner pastes them |
| Generated companion image | rejected by the owner; `sana` is the only keyless Pollinations model and cannot draw a mascot |
| Curated companion image | 512×512 JPEG, 25 KB, uploaded and registered `ready` / `unreviewed`, learner-unreadable, clip gate still shut |

## Not run

| Test | Why |
|------|-----|
| Live Fish TTS with a real key | Owner pastes `VOICE_PROVIDER_API_KEY` during the manual test |
| Live json2video compose with a real key | Owner pastes `VIDEO_PROVIDER_API_KEY` during the manual test; needs an approved companion image in the matching shape |
| Learner-facing published voice / clip | Still a MED-05 approve after generation |
