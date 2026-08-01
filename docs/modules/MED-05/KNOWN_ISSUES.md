# MED-05 known issues

## Never run against a real file

`nano_v1` has zero generated assets, because `generate-asset` is undeployed and
no provider key exists (owner approval, MED-01). Every review path was exercised
against rows planted as `service_role` with a `storage_path` and no object
behind it. What that means in practice:

- The reviewer preview has never rendered a real image.
- Signed-URL generation through `generated_assets_bucket_read_admin` was proven
  by policy, not by a successful download.

The manual test plants the same kind of row, so the owner sees the queue, the
decision, and the audit trail, and sees "Preview unavailable" where the picture
would be.

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
