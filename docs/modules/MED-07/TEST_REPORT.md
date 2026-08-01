# MED-07 test report

## Automated

| Suite | Result |
|-------|--------|
| Deno adapters (`wan_i2v_test.ts` + existing) | **69 passed**, 0 failed |
| `med07_wan_i2v_and_fallback.sql` | **passed** on `nano_v1` |
| Dart `reaction_clip_repository_test`, `asset_review_test`, `generated_asset_repository_test` | **30 passed** |

## Applied on `nano_v1`

| Check | Result |
|-------|--------|
| Migration `med07_wan_i2v_provider_and_fallback` | applied |
| Default video provider | `wan_i2v_space` (`composes_from_art = true`, `requires_key = false`) |
| Fallback | `json2video_compose`, one hop, same kind |
| `generate-asset` redeployed | version 6, ACTIVE, `verify_jwt` on |

## Live

| Check | Result |
|-------|--------|
| Space contract (upload → call → hold SSE → download) | **passed** |
| Late reconnect to a valid event id | **fails** (measured) — adapter therefore has no `generateOrPending` |
| Live Wan render of `guide_greeting` | **passed** — MP4 164 KB in ~27s warm, `provider_id = wan_i2v_space`, `motion = driftIn`, `composed_from_asset_id` set, `cost_micros = 0`, `moderation = unreviewed` |
| Learner-facing published clip | Waiting on Moderation approval |

## Pinning that cost an hour

`frame_multiplier` must be the integer `16`. The published schema says
string; the Space rejects `"16"` with a bare `event: error`. A Deno test
locks the type.
