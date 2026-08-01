# MED-07 manual test

No Docker. Remote project `nano_v1`. No new secrets: the Space needs none,
and the json2video key is already set for the fallback.

## Before you start

1. Confirm `generate-asset` is ACTIVE at version 6+.
2. Confirm admin_web can play video in Moderation (MED-06).

## Steps

### 1. Watch the Wan clip

Open admin_web → Moderation. A `guide_greeting_shortClip` is waiting
`unreviewed`, with `provider_id = wan_i2v_space`, provenance showing
`motion = driftIn` and the approved picture it was made from. Play it.

Expect Nori to wave and blink rather than a camera pan over a still. Decide
it on what you see. Approving publishes it; rejecting frees the slot.

### 2. Unapproved art is still refused

Ask for `celebration_celebration` (no approved art). Expect `NM011` /
`NOT_COMPOSABLE`, and no new asset row. Neither Wan nor json2video is
reached.

### 3. Fallback still works when the Space is unusable

Temporarily set Edge Function secret `VIDEO_SPACE_URL` to a dead host (or
delete the Space URL override if one was set and point it at
`https://example.invalid`). Ask for `guide_greeting` again after rejecting
the previous clip (or for a different aspect if one is authored). Expect:

- An MP4 still lands
- `provider_id = json2video_compose`
- Provenance includes `fell_back_from = wan_i2v_space` and a
  `fallback_reason`

Restore `VIDEO_SPACE_URL` (or clear the override) afterwards.

### 4. Nothing leaked

- No Hugging Face token is required or present.
- Neither the Fish nor the json2video key appears in a client bundle or in
  git.

## Pass criteria

- One Wan MP4 of the greeting sits (or sat) in Moderation for a human decision
- Unapproved art is refused before any provider is called
- An unusable Space falls back to json2video with the swap recorded
- No secrets in git or client bundles
