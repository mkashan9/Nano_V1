# MED-01 decisions

## The caller's token asks, the service role answers

The function could have checked the caller's role itself and then done everything
with the service role. It does not. The first call —
`request_generated_asset` — goes through a client built from the caller's own
authorization header, so the database decides whether that person may ask for
generation. The service role appears only after a row exists, to claim the job and
record what came back.

The reason is blunt: if authorization lived in TypeScript, a bug in the function
would mean anyone with a session could spend money. With the check in SQL, the
worst a function bug can do is fail to generate something.

## Generation is superadmin-only, not "any signed-in adult"

The handbook is explicit that generation belongs in administration workflows, not
in the moment a child opens a screen. So the request RPC requires a platform
admin, and there is no learner-facing entry point at all. A teacher cannot start
one either. This is also the cost control that exists before MED-02's quotas:
nobody who could generate at volume has the ability to try.

## Even a superadmin cannot declare a file ready

`claim_generated_asset` and the two record RPCs are executable by the service role
only, and the advisor check confirmed that after the follow-up migration. A
superadmin can ask for an asset and can review it later, but cannot invent a
`ready` row pointing at a file nobody generated. That keeps "what is published"
answerable from provenance rather than trust.

## The hash covers identity, and failures are outside it

The reuse key is `(kind, prompt_hash)` where the hash spans kind, slot, language,
aspect ratio, prompt version, and the normalized prompt. Whitespace and case do
not create a second asset; a new prompt version does, because the wording changed.

The unique index excludes `failed` rows. That single predicate is what makes a
retry possible without a second table and without deleting the evidence of the
failure: the failed row keeps its attempt history, and a fresh request creates a
new row for the same ask.

## Claim as the lock

Rather than an advisory lock or a queue table, the claim is
`update ... where id = ? and status = 'requested'`. Whoever wins that update owns
the job; a duplicate invocation gets `NM004` and stops. Recording a result has the
same shape (`status = 'generating'`), so a duplicated provider callback cannot add
the cost twice — there is a test that asserts the cost did not move.

## Ready and published are different states

A generated file lands as `ready` with `moderation = 'unreviewed'`, and the client
read path returns approved rows only. So a successful generation today changes
nothing a learner sees, which is exactly the intent: MED-05 owns approval. It also
means the publication gate is enforced in one predicate rather than in whichever
screen happens to be reading.

## A view for admins, a function for clients

The first cut exposed the published projection as a view running with the owner's
rights. The database linter flags that pattern as an error, and it was worth
avoiding rather than inheriting: the view now enforces the caller's RLS (so it
shows an admin their rows and a learner nothing), and clients read through
`list_generated_assets`, a security-definer function that returns the projected
columns only. Prompts, providers, and costs are not columns of that projection, so
they cannot leak through it — there is a test that asks for each of them and
expects the column not to exist.

## The keyless image path first

`pollinations_image` needs no privileged key, so the first end-to-end generation
path in Nano is one where there is no key to leak. Voice and video have the same
adapter shape, read `VOICE_PROVIDER_API_KEY` / `VIDEO_PROVIDER_API_KEY` from
function environment, and report `PROVIDER_UNCONFIGURED` until MED-03 and MED-04
choose providers. An unconfigured provider is a recorded failure, not an
exception, because every companion slot already has a local fallback: a missing
generated extra must never be a broken screen.

## The seed comes from the request hash

Providers that accept a seed get one derived from the prompt hash, so regenerating
an asset that was lost returns the same picture rather than a different one. That
keeps a slot visually stable across a re-run, which matters for a companion the
child recognizes.

## The catalog drops a rung, it does not raise one

`CompanionAssetCatalog.choose` can only ever return the tier the runtime asked for
or something lower. A published clip cannot promote a static moment into an
animated one, an image published against a clip slot is not played as a clip, and
reduced motion collapses to static art regardless of what exists. The ladder stays
a ladder, and the app's behaviour without any generated asset is unchanged.

## Not deployed

The function is committed and unreviewed by any runtime: `ENVIRONMENTS.md` gates
Edge Function deployment on owner approval, and `supabase functions serve` needs
Docker, which the project forbids. So the adapter tests are written and recorded
as NOT RUN, and the live provider round trip is deliberately absent from this
module's evidence rather than claimed.
