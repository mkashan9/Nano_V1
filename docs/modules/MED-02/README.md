# MED-02 — Asset Caching, Hashing, Quotas, and Fallback

## Purpose

MED-01 made a repeat request free. MED-02 makes a new one finite, and makes the
published side cheap to read: every ask is charged against per-day budgets before
a provider is reached, an approved file is delivered through a cacheable signed
URL, and the client asks the server about the catalog roughly never. The fallback
promise from CMP-01 is now explicit rather than implied — when anything in this
chain is missing, slow, or refused, the learner sees local art and no error.

## Deliverables

| Area | What shipped |
|------|--------------|
| Database | `generation_quotas` (platform, feature, and school scopes, per kind or all kinds) and `generation_usage` (today's requests and cost) |
| Database | `generated_assets.feature` and `.school_id` — budget dimensions, deliberately outside the reuse hash |
| Database | `request_generated_asset` now checks reuse first, then charges the budget, then creates the row |
| Database | `record_generated_asset_result` adds the provider's real cost to today's spend |
| Database | `generation_budget_status()` — today's allowance and spend for platform admins, empty for everyone else |
| Database | `nano_internal.asset_object_is_published` plus a storage policy: an approved file is readable by any signed-in client, everything else stays admin-only |
| Edge Function | `generate-asset` passes the feature and school through, returns `QUOTA_EXCEEDED` (429) for a spent budget, and uploads with a one-year `cacheControl` |
| Domain | `GenerationBudget`, `GenerationQuotaScope`, `GenerationQuotaExceeded`, and `CompanionRuntime.withClipsAvailable` |
| nano_media | `CompanionAssetCache`: one fetch per TTL, shared in-flight fetch, last-known-good on failure, signed URLs held until nearly expired and keyed by checksum |
| nano_media | `CompanionArtFallback`: why a reaction is not showing what it asked for |
| Data | `GeneratedAssetRepository.budgets()`, quota refusals mapped to `GenerationQuotaExceeded`, requests carrying their feature and school |
| Student app | The catalog is loaded once behind the first screen and feeds `clipsAvailable`; a sign-out clears it |
| Tests | Adversarial SQL against the development project, Dart unit tests, and a widget test that the app survives a failing catalog |

## Rules

- **A reused ask costs nothing and is charged nothing.** Deduplication happens
  before the budget check. If it were the other way round, a client that cached
  well would be refused for asking about something it already had, which is the
  opposite of what a budget is for.
- **Cost is charged when it is known.** A request adds one to a request counter;
  the worker's result adds the real figure the provider reported. A duplicated
  provider callback is refused by the status predicate, so it cannot charge twice.
- **A refusal happens before a provider is reached.** `NM006` is raised before
  the row is created, so a spent budget costs nothing at all — no row, no claim,
  no call. The message names the scope that ran out.
- **A spent budget is a limit, not a fault.** It surfaces as
  `GenerationQuotaExceeded`, so a caller can say "not today" rather than offering
  a retry that cannot succeed. Nothing about it is a learner's problem.
- **One spent budget is not an outage.** Budgets are per scope and per kind, so
  video running out leaves images working, and a feature running out leaves other
  features working. A zero limit is how something is switched off without a
  deploy.
- **Only an approved file is deliverable.** The storage policy asks the same
  question the catalog does, through a definer helper because the bucket is
  private and the table is admin-only. An unreviewed or failed file is not
  readable by a learner even with its exact path.
- **The client asks rarely and never fails.** Published assets change when a
  curator approves one, so one fetch per TTL is enough. A failed refresh returns
  the last known catalog; a first run with no network returns an empty one. Both
  look the same on screen as a device with nothing published, which is the point.
- **A signed URL is a credential.** They are held only until shortly before
  expiry, keyed by the file's checksum so a regenerated file is signed again
  rather than served from cache, and cleared on sign-out with everything else
  private.
- **Learning that clips exist disturbs nothing.** The answer arrives after
  screens are up, so it leaves the current reaction, the cooldowns, and the
  session budget alone and only affects later reactions.
- **Bytes are cached where bytes belong.** The upload sets a one-year
  `cacheControl` because the path contains the request hash, so the platform's
  HTTP layer and the CDN do the byte caching. Nothing in this module writes a
  file to a device.

## Out of scope

- Changing a budget from a screen; today that is a migration or the service role,
  and the curator surface belongs with review (MED-05)
- Choosing the Aoede voice provider (MED-03) and the clip provider (MED-04)
- Approving an asset, which is what would make the catalog non-empty (MED-05)
- On-device byte caching and true offline media reuse; the sync layer (SYNC-01)
  owns cached data, and no generated asset is required for a screen to work
- Deploying `generate-asset` or setting provider secrets remotely — both need
  owner approval (ADR-0002, `docs/setup/ENVIRONMENTS.md`)
