# MED-02 known issues

- Budgets are read-only from every screen. `generation_quotas` has no write grant
  for `authenticated`, so changing a limit today is a migration or the service
  role. The curator surface that would edit them arrives with MED-05.
- Nothing is published, so the delivery and caching path has never carried a real
  file. The storage policy, the catalog, and the cache are exercised through
  seeded rows and fakes; the first real fetch happens after MED-05 approves
  something.
- Budgets reset on a UTC calendar day, not on a school's local day. For a curator
  workflow that is fine; if per-school budgets ever matter operationally, the
  window will need a timezone.
- Usage is never pruned. `generation_usage` grows by a handful of rows per active
  day and nothing deletes old ones. Retention belongs with reporting, not here.
- Cost is only as accurate as the provider's own reporting. The keyless image path
  reports zero, which is true, and the configured adapters read a header that no
  chosen provider sends yet (MED-03, MED-04).
- A claim that never reports back leaves an asset in `generating` and its request
  already charged. Nothing reaps a stalled claim today, so that budget slot is
  spent for the day. A reaper needs a timeout policy, which is a decision this
  module deliberately did not take alone.
- Storage cleanup is still unhandled, as MED-01 noted. A regenerated file
  overwrites the old one (`upsert: true`) with no version kept, and the one-year
  `cacheControl` means a client or CDN that already has the old bytes under the
  same path could keep serving them. In practice the path contains the request
  hash, so different content means a different path — but a forced regeneration of
  the *same* hash is the case where this bites.
- `CompanionAssetCache` caches metadata only. There is no on-device byte cache, so
  a device that goes offline after loading the catalog can hold a URL it cannot
  fetch. It falls back a rung, which is the same behaviour as a slot with nothing
  generated.
- The student app loads the catalog once at startup and never refreshes within a
  session. A clip approved while the app is open appears on the next launch.
- `withClipsAvailable` is a single global flag. A slot whose clip is missing still
  falls back correctly, but the runtime cannot yet say "clips exist for
  celebrations and not for greetings" before choosing a tier.
