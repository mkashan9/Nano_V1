# MED-06 test report

## Automated

| Check | Result |
|-------|--------|
| `supabase/tests/med06_fish_and_json2video.sql` against `nano_v1` | 7/7 sections pass |
| `supabase/tests/med06_curated_companion_art.sql` against `nano_v1` | 4/4 sections pass |
| `supabase/tests/med06_composition_provenance.sql` against `nano_v1` | 3/3 sections pass |
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
| Migrations applied on `nano_v1` | `med06_fish_and_json2video_providers`, `med06_composed_reaction_clips`, `med06_compose_gate_and_worker_plan`, `med06_curated_companion_art`, `med06_composition_provenance` |
| Default voice / video providers | `fish_audio_voice`, `json2video_compose` (`composes_from_art = true`) |
| Default narration voice | `guide_fish_stock` / `stock` |
| Seeded motions | `guide_greeting` → `driftIn`, `celebration_celebration` → `pushIn`, `quizCoach_celebration` → `dip` |
| `generate-asset` redeployed | version 3, ACTIVE, `verify_jwt` on |
| Keys as Edge Function secrets | **set by the owner** — Fish Audio and json2video both answered live on 2026-08-01 |
| Generated companion image | rejected by the owner; `sana` is the only keyless Pollinations model and cannot draw a mascot |
| Curated companion image | 512×512 JPEG, 25 KB, approved; learners can read it; compose gate open |
| Live Fish TTS | `greeting-2` recorded as MP3, `provider_id = fish_audio_voice`, unreviewed |
| Live json2video compose | `guide_greeting` rendered as MP4 with `motion = driftIn` and `composed_from_asset_id` pointing at the approved picture |
| Unapproved art refusal | `celebration_celebration` refused with `NM011`; no asset row created |

## Live

| Check | Result |
|-------|--------|
| Live Fish TTS with a real key | **passed** — `greeting-2` MP3 landed unreviewed |
| Live json2video compose with a real key | **passed** — `guide_greeting` MP4 landed with motion and source art recorded |
| Learner-facing published voice / clip | Waiting on Moderation approval of the two unreviewed assets |

## Gap caught during the owner's manual test

The owner reached the queue, found an MP4 and an MP3 waiting, and asked how to
play them. Nothing did: MED-05's preview rendered images and described everything
else by content type, size, and checksum. Approving media you cannot open is not
review.

admin_web now plays both in place through the browser's own elements. Verified
by `flutter build web` (clean, and the wasm dry run passes — `package:web`
rather than the deprecated `dart:html`), then by opening the queue against
`nano_v1` and playing each asset. `flutter analyze` reports only the two
pre-existing `unnecessary_underscores` from the content pages; all 22 admin_web
widget tests pass on the VM, where the conditional import resolves the stub and
exercises the metadata fallback.

## Regression caught live

The first composed clip recorded `motion: null` and `composed_from_asset_id: null`.
A composed render spans two invocations; only the first knows the source art, and
the second wrote its own ignorance over the top. Fixed in
`med06_composition_provenance`: the ask stamps the facts, and the recorder merges
provenance without letting nulls erase them. The broken clip was rejected and
re-composed; the second landing is complete.
