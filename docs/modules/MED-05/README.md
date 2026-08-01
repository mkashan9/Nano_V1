# MED-05 — Superadmin Asset Review and Publication

## Purpose

MED-01 through MED-04 taught Nano to generate pictures, voice, and motion.
Nothing they produced has ever reached a child, because `moderation` starts at
`unreviewed` and every learner read filters on `approved`. MED-05 is the missing
half: the decision that turns a generated file into published media, made by a
named superadmin, recorded forever, and reversible in one direction — away from
the learner.

## Deliverables

| Area | What shipped |
|------|--------------|
| Database | `asset_review_events` — append-only audit of every decision, with `seq` for deterministic order |
| Database | `reviewed_by`, `reviewed_at`, `review_note` on `generated_assets` |
| Database | `nano_internal.apply_asset_review` — one decision, one asset, all the refusals |
| Database | `review_generated_assets` (batch, all-or-nothing) and `review_generated_asset` (single) |
| Database | `list_assets_for_review` (the queue) and `asset_review_history` (one asset's record) |
| Database | Reuse index excludes rejected rows; `request_generated_asset` never hands a rejected file back |
| Storage | `generated_assets_bucket_read_admin` — a reviewer can open an unapproved file; a learner still cannot |
| Domain | `AssetReviewItem`, `AssetReviewEvent`, `AssetReviewOutcome`, `AssetReviewRefused` |
| Data | `AssetReviewRepository` with fake and Supabase implementations, including reviewer-signed preview URLs |
| Admin web | Moderation destination: queue, provenance, preview, approve / reject / return, history |
| Copy | Review strings in English and Urdu; `approved` reads as **Published** |
| Tests | Adversarial SQL on `nano_v1`, Dart unit and widget coverage |

## Rules

- **Approval is the only publication.** There is no second switch. A learner sees
  `approved` and nothing else, in both the catalog and storage.
- **Rejection is immediate and total.** Un-publishing removes the file from the
  learner on the next read, not on the next deploy.
- **A rejection needs a sentence.** An empty reason is refused (`NM010`), because
  the next generation has to know what was wrong.
- **An empty asset cannot be published.** Only `ready` rows with a file are
  approvable; a stuck job is visible in the queue but not decidable.
- **Rejecting frees the slot.** The reuse index skips rejected rows, so the next
  ask generates a fresh attempt instead of returning the rejected one.
- **A batch is one decision.** Twenty assets, one round trip, and any refusal
  rolls the whole batch back.
- **Only a platform admin.** School admins, teachers, and learners are refused
  the queue, the decision, and the file — refused, not shown an empty list.
- **Decisions are not editable.** `asset_review_events` rejects `UPDATE` and
  `DELETE` at the trigger, including from the reviewer who wrote the row.

## Out of scope

- ADM-01's full superadmin dashboard; MED-05 adds one destination to the shell
  QZ-01/QZ-02 already built, and ADM-01 will absorb it
- Audio and video playback in the reviewer's browser (no plugin yet; voice and
  video previews show content type, size, and checksum)
- Bulk selection in the UI — the batch RPC exists and is tested; the screen
  decides one asset at a time
- Generating anything: MED-05 reviews what other modules produced

## Provenance

- Moderation column and learner filters: MED-01
- Reuse index and cost accounting: MED-02
- Append-only audit shape: `audit_events` (AUD-01)
- Publish-as-a-decision pattern: QZ-01 `publish_question_version`
- Admin shell, side rail, Moderation destination: QZ-01 / QZ-02
