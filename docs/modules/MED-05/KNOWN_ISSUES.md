# MED-05 known issues

## Images are proven end to end; voice and video are not

`generate-asset` was deployed to `nano_v1` with owner approval after the module
was written, and one real companion image has been generated, stored, and
previewed. That closed the biggest gap:

- The reviewer preview has rendered a real picture.
- `generated_assets_bucket_read_admin` was proven by an actual signed download,
  not only by policy.
- The learner gates were re-checked against that real row: catalog returns
  nothing and the object is unreadable while it is unreviewed.

Voice and video have still never produced a file. Neither
`VOICE_PROVIDER_API_KEY` nor `VIDEO_PROVIDER_API_KEY` is set, so both fail
closed with `PROVIDER_UNCONFIGURED`. The planted rows in the manual test stand
in for them, which also exercises the case that matters most for those kinds: a
preview that cannot load must not block a decision.

## Voice and video previews are metadata

No `just_audio` / `video_player` plugin is attached. Non-image assets show
content type, size, and checksum. A reviewer publishing a clip today is
publishing its provenance.

## Moderation lives on a borrowed shell

ADM-01 (Superadmin Dashboard) is still BACKLOG. MED-05 was approved to build on
the admin shell QZ-01 and QZ-02 shipped. The Moderation destination and its
route already existed; MED-05 filled it. ADM-01 should absorb this screen rather
than replace it.

## Bulk decisions are server-only

`review_generated_assets` takes an array and is tested atomically, but the
screen sends one asset at a time. Multi-select is UI work, not new server work.

## Advisor noise

`learner_quiz` and `learner_quiz_history` SECURITY DEFINER views remain from QZ.
The three new WARNs (`list_assets_for_review`, `review_generated_assets`,
`asset_review_history`) match the existing signed-in + internally gated pattern:
every one of them refuses a non-admin in its own body.

## Local vs remote migration filenames

Applied on `nano_v1` as MCP migrations `med05_asset_review_publication`,
`med05_asset_review_functions`, `med05_asset_review_queue_and_reuse`,
`med05_review_history_order`, and `med05_review_history_cascade`. Git source of
truth is the five `supabase/migrations/2026080118*.sql` files.
