# MED-06 manual test

No Docker. Remote project `nano_v1`. Keys stay in Studio secrets — never in
chat, never in git, never in a `dart-define`.

## Before you start

1. Open Supabase Studio → Project Settings → Edge Functions → Secrets.
2. Paste (do not commit, do not paste back into chat):
   - `VOICE_PROVIDER_API_KEY` = the Fish Audio key
   - `VIDEO_PROVIDER_API_KEY` = the json2video key
3. Optional overrides (leave blank for defaults):
   - `VOICE_PROVIDER_MODEL` (default `s2.1-pro-free`)
   - `VIDEO_COST_MICROS_PER_CLIP` (default `15000`)
4. Confirm `generate-asset` is ACTIVE (version 3+).

## Steps

### 1. Fail-closed still works with no key

Temporarily delete `VOICE_PROVIDER_API_KEY` from secrets (or leave it unset on a
fresh project). As `platform@nano.dev`, invoke `generate-asset` with a published
narration slug. Expect:

- HTTP 200 with `asset.status = failed`
- `asset.error_code = PROVIDER_UNCONFIGURED`
- Captions in the student app unchanged

Restore the key before step 2.

### 2. Record one line

As `platform@nano.dev`, call `generate-asset` with a published narration slug
(for example the greeting line). Expect:

- An MP3 in the `generated-assets` bucket
- Row `kind = voice`, `status = ready`, `moderation = unreviewed`
- `provider_id = fish_audio_voice`
- Learner catalog still empty for that slot

### 3. Approve the companion picture first

Open admin_web → Moderation. Approve the existing
`guide_greeting_staticArt` image (or generate and approve a fresh one in `1:1`).
A clip cannot be composed without this — that is the point of the module.

### 4. Compose one clip

As `platform@nano.dev`, call `generate-asset` with
`{ "clip_slug": "guide_greeting", "aspect_ratio": "1:1" }`. Expect:

- First response may be `pending: true` with a `provider_job_id`
- A later call for the same slug collects the render and lands an MP4
- Row `kind = video`, `status = ready`, `moderation = unreviewed`
- `provider_id = json2video_compose`
- Provenance includes `motion = driftIn` and `composed_from_asset_id`

### 5. Unapproved art is still refused

Reject the companion picture (or leave a different reaction without approved
art). Ask for that reaction's clip. Expect `NOT_COMPOSABLE` / `NM011`, and no
new `generated_assets` row for the clip.

### 6. Nothing leaked

- Search the admin_web and student_app builds for either API key string — zero
  hits.
- Confirm neither key appears in `git log -p` or any committed file.

## Pass criteria

- One Fish MP3 and one json2video MP4 sit unreviewed in the queue
- A missing key fails closed without breaking captions or local art
- A clip without approved art is refused before any money is spent
- Neither key is in git or a client bundle
