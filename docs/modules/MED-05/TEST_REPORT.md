# MED-05 test report

Date: 2026-08-01

## Database (development project `nano_v1`)

Script: `supabase/tests/med05_asset_review_publication.sql`, run block by block
over MCP. Every block is wrapped in `begin … rollback`, and the closing block
confirms the project is back to zero generated assets.

| Check | Result |
|-------|--------|
| Migrations `med05_asset_review_publication`, `_functions`, `_queue_and_reuse`, `_review_history_order`, `_review_history_cascade` | applied |
| Unreviewed asset invisible to a learner; approving publishes it | ok |
| Rejecting un-publishes immediately, catalog and storage | ok |
| Rejected slot can be generated again; rejected file never reused | ok |
| Asset with no file refused; rejection without a reason refused; unknown decision refused; empty batch refused | ok (`NM010`) |
| Re-approving an approved asset is counted unchanged, not re-decided | ok |
| Batch decision is all-or-nothing | ok |
| Un-rejecting into an occupied slot refused instead of duplicating | ok (`NM010`) |
| School admin, teacher, learner: queue refused, decision refused, file unreadable | ok |
| `asset_review_events` rejects `UPDATE` and `DELETE`, including for a privileged caller | ok |
| Deleting a reviewed asset cascades its history away and leaves `audit_events` intact | ok (after fix) |
| Queue lists decidable work first; decisions reach `audit_events` | ok |
| History ordered by `seq`, newest first, for decisions inside one transaction | ok |
| Nothing left behind | 0 generated assets, 0 review events |
| Security advisors | no new ERROR; new WARNs are the three intended review RPCs |

## Dart / Flutter

| Suite | Result |
|-------|--------|
| `asset_review_test.dart` (domain) + `asset_review_repository_test.dart` (data) + `asset_review_page_test.dart` (admin web) | 31 passed |
| Full workspace: domain, data, media, design system, student, teacher, admin | 583 passed |
| `dart analyze` | clean |

Two defects were found and fixed by the tests rather than by review:

- History ordered by timestamp was non-deterministic for two decisions in one
  transaction, so `asset_review_events` gained `seq`.
- The append-only guard also blocked the `on delete cascade`, making a reviewed
  asset undeletable. The guard now refuses direct rewrites only.

One pre-existing failure was fixed on the way through:
`generated_asset_repository_test.dart` still expected `configured_voice` for the
fake's unconfigured voice provider, which MED-03 renamed to
`gemini_voice_aoede`.

## Live pipeline (added after the module was written, on owner approval)

`generate-asset` was deployed to `nano_v1` and one real image was generated
through it, which retires the largest "never run" item.

| Check | Result |
|-------|--------|
| `generate-asset` deployed, `verify_jwt` on | ACTIVE, version 1 |
| Superadmin sign-in → `request_generated_asset` → Pollinations → storage | 17,688-byte JPEG, `ready`, `unreviewed` |
| Charged once, at zero cost (keyless provider) | 1 image request, 0 micros |
| Reviewer signed URL on an unapproved object | downloaded and rendered |
| Learner catalog and storage on that same real row | 0 rows, not readable |

## Not run

| Test | Why |
|------|-----|
| Voice and video generation | No `VOICE_PROVIDER_API_KEY` or `VIDEO_PROVIDER_API_KEY`; both fail closed with `PROVIDER_UNCONFIGURED` |
| Audio / video playback in the reviewer's browser | No player plugin (MED-03, MED-04) |
| Learner-facing published media end to end | Nothing has been approved yet; that is the owner's decision in the manual test |
