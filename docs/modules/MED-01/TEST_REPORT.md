# MED-01 test report

Date: 2026-08-01

## Database (development project `nano_v1`)

| Check | How | Result |
|-------|-----|--------|
| MCP `apply_migration med01_generated_asset_adapters` | Supabase MCP | success |
| MCP `apply_migration med01_generated_asset_grants` | Supabase MCP | success |
| Learner isolation | `execute_sql`, learner JWT | 0 assets, 0 providers, 0 attempts, 0 published |
| Learner cannot request, catalog hides provenance | `execute_sql` | refused; `prompt`, `cost_micros`, `provider_id` are not columns |
| Worker RPCs unreachable by a signed-in caller | `has_function_privilege` | `claim`, `record_result`, `record_failure` all false |
| Superadmin request, dedupe, and hash identity | `execute_sql`, superadmin JWT | 5 rows for 6 asks; identical ask reused; language, aspect ratio, and prompt version each create their own asset |
| Provider registry enforced | `execute_sql` | voice provider refused for an image request (`NM002`), unknown provider refused (`NM002`) |
| Superadmin cannot claim or declare ready | `execute_sql` | refused; asset stayed `requested` |
| Worker claim is single flight | `execute_sql`, service role | second claim `NM004`; one attempt row |
| Result recorded once | `execute_sql` | second result `NM004`; cost unchanged at 1500 |
| Publication gate | `execute_sql` | `ready` + `unreviewed` invisible to `list_generated_assets`; visible once approved |
| Failure keeps provenance and allows a retry | `execute_sql` | attempt closed as failed with its code; a second row for the same hash accepted; empty code refused (`NM005`) |
| Nothing left behind | `execute_sql` | 0 assets, 0 attempts after all blocks rolled back |
| Security advisors | MCP `get_advisors` | no new ERROR; the two new WARNs are the intended signed-in RPCs (`request_generated_asset`, `list_generated_assets`) |

The full script is `supabase/tests/med01_generated_asset_adapters.sql`; it was run
in blocks through MCP `execute_sql`, each block inside a transaction that rolled
back.

## Dart

| Suite | Command | Result |
|-------|---------|--------|
| Domain | `dart test packages/nano_domain` | 206 passed (8 new generated-asset tests) |
| Data | `dart test packages/nano_data` | 79 passed (7 new repository tests) |
| nano_media | `dart test packages/nano_media` | 9 passed (all new) |
| Design system | `flutter test packages/nano_design_system` | 41 passed |
| Student app | `flutter test apps/student_app` | 113 passed |
| Admin web | `flutter test apps/admin_web` | 13 passed |
| Static analysis | `dart analyze packages/nano_domain packages/nano_data packages/nano_media` | 3 pre-existing issues, none in new files |

### New coverage

`packages/nano_domain/test/generated_asset_test.dart`

- The published projection reads as ready and approved, with no provenance
- An admin row keeps its provenance and stays unplayable until approved
- A failed row carries a reason and no file
- Unknown enum values fall back instead of throwing
- A companion request uses the same slot key the runtime looks up
- RPC parameter names are fixed by the model, not composed by a caller
- Reuse is reported, so a caller can tell nothing was paid for

`packages/nano_media/test/companion_asset_catalog_test.dart`

- Only ready, approved assets with a file enter the catalog
- A missing language falls back to English rather than to nothing
- `hasClips` is what lets the runtime promise a clip
- A published clip is used for its own slot, and is not borrowed for another
- A missing clip drops one rung; an image against a clip slot does too
- Reduced motion never gets a clip, even when one exists
- A local tier is unaffected by anything published

`packages/nano_data/test/generated_asset_repository_test.dart`

- The published list hides anything unapproved or unfinished
- An identical ask reuses the existing asset
- A new slot creates a ready asset that is not yet published
- An unconfigured provider fails the request without a file
- Failures surface as errors rather than empty lists
- A signed URL is per asset and time limited

## Not run

- `supabase/functions/generate-asset/adapters/adapters_test.ts` — **NOT RUN**: no
  Deno toolchain on this machine (`deno --version` not found). The tests are
  committed and cover dimension mapping, seed stability, the prompt/size/seed the
  image adapter sends, error-code mapping, the empty-response guard, the
  unconfigured-key path, and registry refusals.
- Live provider round trip and Edge Function execution — **NOT RUN**: deployment
  is owner-gated (`docs/setup/ENVIRONMENTS.md`) and local serving would need
  Docker, which ADR-0002 forbids.
- Storage upload path — **NOT RUN** for the same reason; the bucket and its
  read policy exist and were verified, but nothing has written to it.

## Security

- No provider key exists in any Dart or Flutter file: `rg "PROVIDER_API_KEY|service_role" apps packages --glob "*.dart"` returns nothing.
- `api_s.txt`, `github.txt`, and `.env*` were not read or referenced;
  `.env.example` gained two variable names and no values.
- Prompts, providers, costs, and attempt history are readable by platform admins
  only; the client path returns file identity for approved assets.
