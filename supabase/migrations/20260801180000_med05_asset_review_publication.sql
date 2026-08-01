-- MED-05: Superadmin Asset Review and Publication (schema)
--
-- MED-01 through MED-04 built a generation pipeline whose output nobody can see.
-- Every row lands as `unreviewed`, and both learner-facing gates -- the
-- generated_asset_catalog view and the storage read policy -- require
-- `approved`. This module owns that transition and nothing else.
--
-- Three things it has to get right, two of which are in this file:
--
--   1. A reviewer must be able to look at the actual file before deciding.
--      MED-02's storage policy only exposes approved objects, which would leave
--      a reviewer approving a filename. A second, admin-only read policy fixes
--      that without widening anything for a learner.
--
--   2. Rejecting must free the slot. The MED-01 reuse index keys on
--      (kind, prompt_hash) for every row that is not `failed`, so a rejected
--      asset would be handed back forever as a reuse and the slot could never
--      be regenerated. One bad generation would poison its slot permanently.
--
--   3. A decision needs a name on it. Publication is the moment platform
--      content reaches children, so who decided, when, and why is kept in an
--      append-only record and mirrored into the SEC-03 audit trail.
--
-- The functions live in the two migrations that follow this one.

-- ---------------------------------------------------------------------------
-- Review state on the asset
-- ---------------------------------------------------------------------------
alter table public.generated_assets
  add column if not exists reviewed_by uuid references public.profiles (id),
  add column if not exists reviewed_at timestamptz,
  add column if not exists review_note text;

comment on column public.generated_assets.reviewed_by is
  'MED-05 who last decided. Null while the asset is still in the queue.';

comment on column public.generated_assets.review_note is
  'MED-05 why. Required for a rejection so whoever regenerates knows what to fix.';

-- Rejection frees the slot. Without the moderation predicate a rejected row
-- stays the reuse winner for its hash and the same refused output is returned
-- to every later ask.
drop index if exists generated_assets_reuse_idx;
create unique index generated_assets_reuse_idx
  on public.generated_assets (kind, prompt_hash)
  where status <> 'failed' and moderation <> 'rejected';

create index if not exists generated_assets_review_queue_idx
  on public.generated_assets (moderation, status, requested_at desc);

-- ---------------------------------------------------------------------------
-- The decision record
-- ---------------------------------------------------------------------------
create table if not exists public.asset_review_events (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.generated_assets (id) on delete cascade,
  reviewer_id uuid references public.profiles (id),
  previous_moderation public.generated_asset_moderation not null,
  decision public.generated_asset_moderation not null,
  note text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  constraint asset_review_events_changed check (decision <> previous_moderation),
  constraint asset_review_events_rejection_has_reason check (
    decision <> 'rejected' or btrim(note) <> ''
  )
);

comment on table public.asset_review_events is
  'MED-05 append-only history of publication decisions. One row per actual '
  'change of moderation state; re-approving something already approved records '
  'nothing because nothing happened.';

create index if not exists asset_review_events_asset_idx
  on public.asset_review_events (asset_id, created_at desc);
create index if not exists asset_review_events_reviewer_idx
  on public.asset_review_events (reviewer_id, created_at desc);

alter table public.asset_review_events enable row level security;

drop policy if exists asset_review_events_select on public.asset_review_events;
create policy asset_review_events_select on public.asset_review_events
  for select to authenticated
  using (nano_internal.is_platform_admin());

-- Written only by the definer function in the next migration, and never
-- amended afterwards.
revoke insert, update, delete on public.asset_review_events from authenticated;

-- A history that can be rewritten is not a history. Even a future migration
-- that hands out table privileges by accident cannot quietly edit the record.
create or replace function nano_internal.asset_review_events_are_final()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  raise exception using
    errcode = 'NM010',
    message = 'Review history is append-only.';
end;
$$;

drop trigger if exists asset_review_events_no_rewrite on public.asset_review_events;
create trigger asset_review_events_no_rewrite
  before update or delete on public.asset_review_events
  for each row execute function nano_internal.asset_review_events_are_final();

-- ---------------------------------------------------------------------------
-- Reviewer preview
-- ---------------------------------------------------------------------------
-- MED-02 lets any signed-in client read an approved object so the CDN can keep
-- the bytes. A reviewer needs the opposite: everything, including what is not
-- approved yet. Select policies are OR'd, so this adds the admin path without
-- touching the learner path.
drop policy if exists generated_assets_bucket_read_admin on storage.objects;
create policy generated_assets_bucket_read_admin on storage.objects
  for select to authenticated
  using (
    bucket_id = 'generated-assets'
    and nano_internal.is_platform_admin()
  );
