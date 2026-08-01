# MED-01 — Generated Asset Provider Adapters

## Purpose

Give Nano one server-side way to turn a prompt into a stored file, with the
provider key never leaving the Edge Function and the cost of a repeat request
being zero. CMP-01 already defined the asset ladder and left `clipsAvailable`
false; this module builds the machinery that can eventually make it true, without
letting a generated extra become something a screen depends on.

## Deliverables

| Area | What shipped |
|------|--------------|
| Database | `generation_providers` registry, `generated_assets`, `generation_attempts`, plus the private `generated-assets` storage bucket |
| Database | `request_generated_asset` (superadmin), `claim_generated_asset` / `record_generated_asset_result` / `record_generated_asset_failure` (worker only), `list_generated_assets` (clients) |
| Database | `nano_internal.generated_asset_hash`: kind, slot, language, aspect ratio, prompt version, normalized prompt |
| Edge Function | `generate-asset` — the first Edge Function in the repo, and the only caller of a provider |
| Adapters | `pollinations_image` (keyless, real), `configured_voice` and `configured_video` (contract plus graceful unconfigured failure) |
| Domain | `GeneratedAsset`, kind/status/moderation, `GeneratedAssetRequest`, `GeneratedAssetOutcome` |
| Data | `GeneratedAssetRepository` with fake and Supabase implementations |
| nano_media | `CompanionAssetCatalog`: published assets by slot and language, and the drop-a-rung decision that feeds the CMP-01 ladder |
| Tests | Adversarial SQL against the development project, Dart unit tests, and Deno adapter tests (recorded NOT RUN — see TEST_REPORT) |

## Rules

- **No provider key exists outside an Edge Function.** The image path was chosen
  first precisely because it needs no key, so the first working generation path
  in Nano cannot leak one. Voice and video read their key from function
  environment and nothing else.
- **A learner cannot start generation.** `request_generated_asset` refuses
  anyone who is not a platform admin, which matches the handbook: generation
  happens in administration workflows, not when a child opens a screen.
- **Only the worker records outcomes.** Claiming a job and declaring a file ready
  require the service role. A superadmin can ask for an asset and cannot fake
  one — the RPCs are not merely refused for a signed-in caller, they are not
  executable by one.
- **The same ask is answered once.** The request is hashed over everything that
  changes the output. A second identical ask returns the first row and no
  provider is called. A different language, aspect ratio, slot, or prompt version
  is a different asset, because it is a different output.
- **A claim is single flight.** The status predicate on the claim update is the
  lock, so a retried function invocation cannot start a second paid call for one
  asset.
- **Ready is not published.** A generated file is `unreviewed` until MED-05
  approves it, and the client read path returns approved rows only. That is why
  `list_generated_assets` is empty today even after a successful generation.
- **A failure is data, not an outage.** Failed rows keep their provenance, are
  excluded from the reuse index so the ask can be retried, and never reach a
  learner. `PROVIDER_UNCONFIGURED` is the expected voice and video outcome until
  MED-03 and MED-04 choose providers.
- **Nothing generated is ever required.** `CompanionAssetCatalog` drops a rung
  when a clip is missing, unapproved, or the wrong kind, and reduced motion never
  gets a clip even when one exists.
- **A client never sees how an asset was made.** The published projection carries
  the file identity only: no prompt, no provider, no cost. The base table is
  admin-only, so provenance cannot leak through a wider select.

## Out of scope

- Quotas, per-school budgets, caching, and offline reuse (MED-02)
- Choosing the Aoede voice provider and generating narration (MED-03)
- Choosing the clip provider and the reusable reaction library (MED-04)
- The superadmin review and publication screen, and any moderation transition
  (MED-05)
- Deploying `generate-asset` or setting provider secrets remotely — both need
  owner approval (ADR-0002, `docs/setup/ENVIRONMENTS.md`)
- Bundled companion art; the ladder still resolves to the placeholder the design
  system draws today
