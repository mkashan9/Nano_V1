# MED-02 decisions

## Reuse is checked before the budget

The obvious order is to check the budget first — it is the gate, so gate first.
That would mean a client which asks for something already generated can be
refused for being over a limit, even though answering it costs nothing. It would
punish exactly the behaviour a cache is supposed to encourage.

So the order is: resolve the provider, hash the ask, return an existing row if
there is one, and only then charge a budget. A budget limits *new* work, which is
the only work that costs anything.

## The feature and the school are outside the reuse hash

A budget wants to know who asked. A hash wants to know what was asked for. They
are different questions, and mixing them would mean the companion and onboarding
asking for the same picture generate it twice and pay twice.

So `feature` and `school_id` are columns on the asset, used for budgets and
reporting, and they are not part of `generated_asset_hash`. One output, one file,
one payment, whoever asked for it.

## Requests are counted at request time, cost at result time

Cost cannot be known before the provider answers. Estimating it would mean
carrying a table of guessed prices per provider, and being wrong in both
directions: refusing work that was affordable, and allowing work that was not.

So the counters are split. `request_generated_asset` adds one to a request count,
which is what enforces "how much may be asked for today".
`record_generated_asset_result` adds the real figure the provider reported, which
is what enforces "how much may be spent today". A duplicated provider callback
cannot double-charge, because the status predicate on the result update refuses
the second one.

## A zero limit is the off switch

Rather than an `is_enabled` flag per kind and per feature on top of numeric
limits, a limit of zero means blocked. One mechanism, no ambiguity about which of
two flags wins, and switching video off for a day is a single number.

## Budgets are not editable from any screen yet

`generation_quotas` has no write grant for `authenticated`, superadmin included.
That is deliberate for now: the curator surface that would edit them is MED-05,
and inventing a write path here would mean inventing its authorization too.
Changing a budget today is a migration or the service role, which is also why the
SQL suite has to change budgets before switching role.

## The delivery gate is a definer helper, not a policy subquery

The natural storage policy is `exists (select 1 from generated_assets where …)`.
It does not work: the bucket is private and `generated_assets` is admin-only, so
as a learner that subquery sees no rows and every file is refused.

`nano_internal.asset_object_is_published(name)` answers one boolean under the
owner's rights, and the policy asks only that. It cannot be used to enumerate
anything — it takes an exact path and returns true or false — and it asks the same
question the catalog asks, so publication has exactly one meaning.

## Clients mint their own signed URLs

The alternative is a second Edge Function that returns a URL, so the server
controls delivery. It buys nothing here: a signed URL is already time-limited and
already gated by the storage policy, and a function in the path means a cold
start between a learner and a picture, plus another deployment that must exist
before anything works.

## The client cache holds metadata, not bytes

Byte caching on device would mean a file store, a size budget, an eviction
policy, and platform paths — and `nano_media` would stop being pure Dart and
testable. It is also unnecessary: the upload sets a one-year `cacheControl` and
the path contains the request hash, so the HTTP layer and the CDN cache the bytes
correctly without us writing any of it.

What the client caches is the catalog and the signed URLs, which are the parts
that cost a round trip rather than bandwidth.

## A failed fetch returns the last good answer, or an empty one

`CompanionAssetCache.load` never throws. On a first run with no network it
returns an empty catalog, which is *exactly* what a device with nothing published
has — and since nothing generated is ever required, both are already a supported
state. Making the caller handle an exception would mean writing an error path for
a situation that is indistinguishable from normal.

The failure is kept in `lastError` for diagnostics, and nothing on screen changes.

## Signed URLs are keyed by checksum

Keying by asset id would serve a stale URL after a file is regenerated under the
same identity. Keying by checksum means new bytes are a new key, and a refresh
drops URLs for files that are no longer published — so a sign-out or a
republication cannot leave a working link to something a learner should not have.

## Learning that clips exist is not a session reset

`withClipsAvailable` carries `lastShownAt` and `shownThisSession` across. The
catalog arrives a moment after the first screen is up, and a learner should not
see Nori appear twice, or lose a cooldown, because a background fetch finished.
Only the tier of a future reaction changes.
