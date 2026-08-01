-- MED-04: short companion clips, and the library that makes them reusable.
--
-- Three ideas, and the third is the one that changes how the app behaves.
--
-- 1. **A clip is authored, not prompted.** `reaction_clips` and
--    `reaction_clip_versions` follow the MED-03 pattern: a stable slug, versioned
--    direction, draft → published → retired, published rows immutable. A caller
--    names a reaction, never a prompt, so nobody can quietly generate a clip of
--    something no curator approved.
--
-- 2. **The slug is a reaction, not a screen.** It is `<mode>_<mood>` — exactly the
--    first two segments of `CompanionReaction.assetKey`. Author
--    `celebration_celebration` once and every surface that reaches Celebration
--    Nori celebrating uses it. That is the reusable part of the library, and it is
--    why the slug keeps Dart's casing (`quizCoach_thinking`, not `quizcoach_...`):
--    a slug that does not round-trip to `assetKey` is a slug that silently never
--    matches.
--
-- 3. **A clip is silent and language-neutral.** No `_ur` column and no per-language
--    request. A recording is words, so MED-03 split it by language; a clip is
--    motion, so splitting it by language would pay twice for identical frames. It
--    is stored under `en` and the client's existing English fallback hands it to
--    an Urdu learner unchanged.
--
-- Clips also force an honesty this pipeline had not needed yet: they take minutes.
-- A claim that was single-flight forever is fine for a two-second image and wrong
-- for a two-minute clip, because a worker that dies mid-job leaves the row
-- `generating` and the reuse index then means *nobody can ever ask for that clip
-- again*. So a claim now expires, an expired claim is released back to the queue
-- by the next asker, and a job that has failed to finish enough times is failed
-- properly instead of retried forever.

-- ---------------------------------------------------------------------------
-- The provider
-- ---------------------------------------------------------------------------
-- Veo through the Gemini API. Unlike every provider before it this one is
-- asynchronous: the call returns an operation name and the bytes arrive later,
-- which is what the claim and polling columns below exist to survive.
insert into public.generation_providers
  (id, kind, is_enabled, is_default, requires_key, notes)
values (
  'gemini_veo_video',
  'video',
  true,
  false,
  true,
  'Short companion clips via Veo; VIDEO_PROVIDER_API_KEY in Edge Function env. '
  'Asynchronous: submit returns an operation, bytes arrive on a later poll.'
)
on conflict (id) do nothing;

-- One default per kind is a partial unique index checked row by row, so the old
-- default steps down in its own statement before the new one steps up.
update public.generation_providers
set is_default = false
where kind = 'video' and id <> 'gemini_veo_video';

update public.generation_providers
set is_default = true
where id = 'gemini_veo_video';

-- ---------------------------------------------------------------------------
-- Surviving a long job
-- ---------------------------------------------------------------------------
alter table public.generated_assets
  add column if not exists claim_expires_at timestamptz,
  add column if not exists provider_job_id text,
  add column if not exists poll_after timestamptz;

comment on column public.generated_assets.claim_expires_at is
  'MED-04 when this claim stops being believed. A worker that dies mid-clip would '
  'otherwise hold the row generating forever, and the reuse index would make the '
  'slot unaskable for good.';

comment on column public.generated_assets.provider_job_id is
  'MED-04 the provider''s handle for an asynchronous job, so a later invocation '
  'can collect a clip the invocation that started it never saw finish.';

comment on column public.generated_assets.poll_after is
  'MED-04 earliest sensible time to ask the provider again. Polling a video job '
  'every second is how a quota is spent on questions rather than clips.';

-- Work a resuming worker should look at: still generating, still believed, and due.
create index if not exists generated_assets_pending_idx
  on public.generated_assets (poll_after)
  where status = 'generating';

-- How long a claim is believed. A clip is minutes, not seconds; anything shorter
-- would have two workers on one job, which is the expensive mistake.
create or replace function nano_internal.generation_claim_ttl(
  p_kind public.generated_asset_kind
)
returns interval
language sql
immutable
set search_path = pg_catalog
as $$
  select case p_kind
    when 'video' then interval '20 minutes'
    when 'voice' then interval '5 minutes'
    else interval '3 minutes'
  end;
$$;

revoke all on function nano_internal.generation_claim_ttl(
  public.generated_asset_kind
) from public, anon;
grant execute on function nano_internal.generation_claim_ttl(
  public.generated_asset_kind
) to authenticated, service_role;

-- Give up after this many tries. Without a ceiling, a provider that always fails
-- at minute nineteen turns into an unbounded spend.
create or replace function nano_internal.generation_max_attempts()
returns integer
language sql
immutable
set search_path = pg_catalog
as $$
  select 3;
$$;

revoke all on function nano_internal.generation_max_attempts() from public, anon;
grant execute on function nano_internal.generation_max_attempts()
  to authenticated, service_role;

-- Put an abandoned job back in the queue, or fail it if it has had its chances.
--
-- Returns true when the row is askable again. Deliberately silent about rows that
-- are healthy: a live claim, a finished asset, and a failed one are all "no".
create or replace function nano_internal.release_stale_generation(p_asset_id uuid)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_asset public.generated_assets;
begin
  select * into v_asset
  from public.generated_assets
  where id = p_asset_id;

  if v_asset.id is null or v_asset.status <> 'generating' then
    return false;
  end if;
  -- A claim with no expiry predates this module. Treat it as live rather than
  -- guessing, so an upgrade cannot restart jobs that are genuinely running.
  if v_asset.claim_expires_at is null
     or v_asset.claim_expires_at > timezone('utc', now()) then
    return false;
  end if;

  if v_asset.attempts_count >= nano_internal.generation_max_attempts() then
    update public.generated_assets
    set status = 'failed',
        error_code = 'GENERATION_ABANDONED',
        error_message = 'The provider never finished this job.',
        completed_at = timezone('utc', now()),
        claim_expires_at = null,
        poll_after = null
    where id = p_asset_id;

    -- A failed row leaves the reuse index, so the slot can be asked for again
    -- from scratch — and that ask is charged, because it is a new job.
    insert into public.audit_events
      (actor_user_id, actor_role, action, target_type, target_id, new_value)
    values (
      null, 'service_role', 'update', 'generated_asset', p_asset_id::text,
      jsonb_build_object(
        'status', 'failed',
        'error_code', 'GENERATION_ABANDONED',
        'attempts_count', v_asset.attempts_count
      )
    );
    return false;
  end if;

  update public.generated_assets
  set status = 'requested',
      claimed_at = null,
      claim_expires_at = null,
      provider_job_id = null,
      poll_after = null
  where id = p_asset_id;

  update public.generation_attempts
  set outcome = 'failed',
      error_code = 'CLAIM_EXPIRED',
      error_message = 'The worker never reported back.',
      finished_at = timezone('utc', now())
  where asset_id = p_asset_id
    and attempt_number = v_asset.attempts_count
    and outcome is null;

  return true;
end;
$$;

revoke all on function nano_internal.release_stale_generation(uuid)
  from public, anon;
grant execute on function nano_internal.release_stale_generation(uuid)
  to authenticated, service_role;

-- The claim now carries an expiry, so the row says when to stop believing it.
create or replace function public.claim_generated_asset(p_asset_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_asset public.generated_assets;
  v_attempt integer;
begin
  if not nano_internal.is_generation_worker() then
    raise exception using
      errcode = 'NM003',
      message = 'Only the generation worker can claim an asset.';
  end if;

  -- An abandoned job is returned to the queue before we look, so a crashed clip
  -- is retried by the next worker instead of blocking the slot forever.
  perform nano_internal.release_stale_generation(p_asset_id);

  -- The status predicate is the lock: two workers cannot both win this update.
  update public.generated_assets
  set status = 'generating',
      claimed_at = timezone('utc', now()),
      claim_expires_at =
        timezone('utc', now()) + nano_internal.generation_claim_ttl(kind),
      attempts_count = attempts_count + 1,
      error_code = null,
      error_message = null
  where id = p_asset_id and status = 'requested'
  returning * into v_asset;

  if v_asset.id is null then
    raise exception using
      errcode = 'NM004',
      message = 'That asset is not waiting for generation.';
  end if;

  v_attempt := v_asset.attempts_count;

  insert into public.generation_attempts
    (asset_id, provider_id, attempt_number)
  values (v_asset.id, v_asset.provider_id, v_attempt);

  return jsonb_build_object(
    'attempt_number', v_attempt,
    'asset', nano_internal.generated_asset_json(v_asset.id)
  );
end;
$$;

comment on function public.claim_generated_asset(uuid) is
  'MED-01/04 worker claim. The status predicate makes it single flight; the '
  'expiry makes it recoverable when a long job dies.';

revoke all on function public.claim_generated_asset(uuid) from public, anon;
grant execute on function public.claim_generated_asset(uuid) to service_role;

-- A job that is still running says so, and says when to ask again.
create or replace function public.record_generated_asset_progress(
  p_asset_id uuid,
  p_provider_job_id text default null,
  p_poll_after_seconds integer default 15
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_asset public.generated_assets;
begin
  if not nano_internal.is_generation_worker() then
    raise exception using
      errcode = 'NM003',
      message = 'Only the generation worker can report progress.';
  end if;

  -- Progress renews the claim. A job that is demonstrably alive should not be
  -- taken away from the worker that is watching it.
  update public.generated_assets
  set provider_job_id =
        coalesce(nullif(btrim(coalesce(p_provider_job_id, '')), ''),
                 provider_job_id),
      poll_after = timezone('utc', now())
        + make_interval(secs => greatest(coalesce(p_poll_after_seconds, 15), 1)),
      claim_expires_at =
        timezone('utc', now()) + nano_internal.generation_claim_ttl(kind)
  where id = p_asset_id and status = 'generating'
  returning * into v_asset;

  if v_asset.id is null then
    raise exception using
      errcode = 'NM004',
      message = 'That asset is not generating.';
  end if;

  return nano_internal.generated_asset_json(v_asset.id);
end;
$$;

comment on function public.record_generated_asset_progress(uuid, text, integer) is
  'MED-04 an asynchronous job checking in. Renews the claim and records the '
  'provider handle so a later invocation can collect the result.';

revoke all on function public.record_generated_asset_progress(uuid, text, integer)
  from public, anon, authenticated;
grant execute on function public.record_generated_asset_progress(uuid, text, integer)
  to service_role;

-- What a resuming worker should pick up: jobs that are due, oldest first.
create or replace function public.list_pending_generated_assets(
  p_limit integer default 10
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_rows jsonb;
begin
  if not nano_internal.is_generation_worker() then
    raise exception using
      errcode = 'NM003',
      message = 'Only the generation worker can list pending work.';
  end if;

  select coalesce(jsonb_agg(row_json order by requested_at), '[]'::jsonb)
  into v_rows
  from (
    select
      ga.requested_at,
      jsonb_build_object(
        'id', ga.id,
        'kind', ga.kind,
        'provider_id', ga.provider_id,
        'provider_job_id', ga.provider_job_id,
        'slot', ga.slot,
        'locale', ga.locale,
        'attempts_count', ga.attempts_count,
        'claim_expires_at', ga.claim_expires_at
      ) as row_json
    from public.generated_assets ga
    where ga.status = 'generating'
      and ga.provider_job_id is not null
      and (ga.poll_after is null or ga.poll_after <= timezone('utc', now()))
      and (ga.claim_expires_at is null
           or ga.claim_expires_at > timezone('utc', now()))
    order by ga.requested_at
    limit greatest(coalesce(p_limit, 10), 1)
  ) as due;

  return v_rows;
end;
$$;

comment on function public.list_pending_generated_assets(integer) is
  'MED-04 asynchronous jobs waiting to be collected. Worker only: it names '
  'providers and job handles, which is authoring detail.';

revoke all on function public.list_pending_generated_assets(integer)
  from public, anon, authenticated;
grant execute on function public.list_pending_generated_assets(integer)
  to service_role;

-- Finishing or failing a job clears its scheduling state, so nothing keeps
-- polling a job that is done.
create or replace function nano_internal.clear_generation_schedule()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if new.status in ('ready', 'failed')
     and (new.claim_expires_at is not null or new.poll_after is not null) then
    new.claim_expires_at := null;
    new.poll_after := null;
  end if;
  return new;
end;
$$;

drop trigger if exists generated_assets_clear_schedule on public.generated_assets;
create trigger generated_assets_clear_schedule
  before update on public.generated_assets
  for each row execute function nano_internal.clear_generation_schedule();

-- ---------------------------------------------------------------------------
-- The reaction clip library
-- ---------------------------------------------------------------------------
create table if not exists public.reaction_clips (
  id uuid primary key default gen_random_uuid(),
  -- `<mode>_<mood>`, matching Dart exactly, casing included. The check is
  -- deliberately camelCase-aware: `quizCoach_gentleRetry` is a real reaction.
  slug text not null unique check (slug ~ '^[a-z][a-zA-Z0-9]*_[a-z][a-zA-Z0-9]*$'),
  mode text not null check (
    mode in ('guide', 'explorer', 'quizCoach', 'builder', 'celebration')
  ),
  mood text not null check (
    mood in ('greeting', 'idle', 'point', 'thinking', 'gentleRetry', 'celebration')
  ),
  notes text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint reaction_clips_slug_matches_pair check (slug = mode || '_' || mood)
);

comment on table public.reaction_clips is
  'MED-04 stable identity of a companion reaction that may have a clip. The slug '
  'is the mode and mood pair from CompanionReaction.assetKey, so one authored '
  'clip serves every surface that reaches that reaction.';

drop trigger if exists reaction_clips_set_updated_at on public.reaction_clips;
create trigger reaction_clips_set_updated_at
  before update on public.reaction_clips
  for each row execute function public.set_updated_at();

create table if not exists public.reaction_clip_versions (
  id uuid primary key default gen_random_uuid(),
  clip_id uuid not null references public.reaction_clips (id) on delete cascade,
  version integer not null check (version >= 1),
  status text not null default 'draft'
    check (status in ('draft', 'published', 'retired')),
  -- What the clip should show. This is a prompt, so it is authoring detail and
  -- never reaches a learner's client.
  direction text not null check (btrim(direction) <> ''),
  -- Shapes this direction was written for. A clip framed for a story card is not
  -- the same clip letterboxed into an inline row, so an unauthored shape is
  -- refused rather than generated and hoped for.
  aspect_ratios text[] not null default array['1:1'],
  duration_seconds integer not null default 4
    check (duration_seconds between 1 and 8),
  direction_hash text not null,
  created_by uuid references public.profiles (id),
  published_at timestamptz,
  published_by uuid references public.profiles (id),
  retired_at timestamptz,
  retired_by uuid references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint reaction_clip_versions_unique unique (clip_id, version),
  constraint reaction_clip_versions_shapes check (
    array_length(aspect_ratios, 1) > 0
    and aspect_ratios <@ array['1:1', '4:3', '3:4', '16:9', '9:16']
  )
);

comment on table public.reaction_clip_versions is
  'MED-04 versioned clip direction. A published version is immutable, so an '
  'approved clip can never quietly become a clip of different direction.';

-- One published version per reaction: the app asks for a reaction, not a version.
create unique index if not exists reaction_clip_versions_published_idx
  on public.reaction_clip_versions (clip_id)
  where status = 'published';

drop trigger if exists reaction_clip_versions_set_updated_at
  on public.reaction_clip_versions;
create trigger reaction_clip_versions_set_updated_at
  before update on public.reaction_clip_versions
  for each row execute function public.set_updated_at();

create or replace function nano_internal.reaction_clip_hash(
  p_direction text,
  p_duration_seconds integer
)
returns text
language sql
immutable
set search_path = pg_catalog, public, nano_internal, extensions
as $$
  select encode(
    extensions.digest(
      concat_ws(
        '|',
        nano_internal.normalize_generation_prompt(p_direction),
        coalesce(p_duration_seconds, 4)::text
      ),
      'sha256'
    ),
    'hex'
  );
$$;

revoke all on function nano_internal.reaction_clip_hash(text, integer)
  from public, anon;
grant execute on function nano_internal.reaction_clip_hash(text, integer)
  to authenticated, service_role;

create or replace function nano_internal.reaction_clip_guard()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if old.status = 'published' and (
    new.direction is distinct from old.direction
    or new.aspect_ratios is distinct from old.aspect_ratios
    or new.duration_seconds is distinct from old.duration_seconds
    or new.version is distinct from old.version
    or new.clip_id is distinct from old.clip_id
  ) then
    raise exception using
      errcode = 'NM008',
      message = 'A published reaction clip cannot be edited. Publish a new version.';
  end if;
  return new;
end;
$$;

drop trigger if exists reaction_clip_versions_guard on public.reaction_clip_versions;
create trigger reaction_clip_versions_guard
  before update on public.reaction_clip_versions
  for each row execute function nano_internal.reaction_clip_guard();

alter table public.reaction_clips enable row level security;
alter table public.reaction_clip_versions enable row level security;

drop policy if exists reaction_clips_select on public.reaction_clips;
create policy reaction_clips_select on public.reaction_clips
  for select to authenticated
  using (nano_internal.is_platform_admin());

drop policy if exists reaction_clip_versions_select on public.reaction_clip_versions;
create policy reaction_clip_versions_select on public.reaction_clip_versions
  for select to authenticated
  using (nano_internal.is_platform_admin());

revoke insert, update, delete on public.reaction_clips from authenticated;
revoke insert, update, delete on public.reaction_clip_versions from authenticated;

-- One function, so the slot a request writes and the slot a client looks up can
-- never disagree. The `shortClip` suffix is Dart's tier name, not a word we chose
-- here, which is why it is spelled exactly like that.
create or replace function nano_internal.reaction_clip_slot(p_slug text)
returns text
language sql
immutable
set search_path = pg_catalog
as $$
  select btrim(coalesce(p_slug, '')) || '_shortClip';
$$;

revoke all on function nano_internal.reaction_clip_slot(text) from public, anon;
grant execute on function nano_internal.reaction_clip_slot(text)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Authoring
-- ---------------------------------------------------------------------------
create or replace function public.create_reaction_clip_draft(
  p_slug text,
  p_direction text,
  p_aspect_ratios text[] default array['1:1'],
  p_duration_seconds integer default 4,
  p_notes text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_slug text := btrim(coalesce(p_slug, ''));
  v_mode text;
  v_mood text;
  v_clip_id uuid;
  v_version integer;
  v_id uuid;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NM001',
      message = 'Only platform admins can author reaction clips.';
  end if;

  v_mode := split_part(v_slug, '_', 1);
  v_mood := split_part(v_slug, '_', 2);
  if v_mode = '' or v_mood = '' or v_slug <> v_mode || '_' || v_mood then
    raise exception using
      errcode = 'NM009',
      message = 'A reaction slug is exactly one mode and one mood, joined by _.';
  end if;

  insert into public.reaction_clips (slug, mode, mood, notes)
  values (v_slug, v_mode, v_mood, p_notes)
  on conflict (slug) do update
    set notes = case
          when btrim(excluded.notes) = '' then public.reaction_clips.notes
          else excluded.notes
        end
  returning id into v_clip_id;

  select coalesce(max(version), 0) + 1 into v_version
  from public.reaction_clip_versions
  where clip_id = v_clip_id;

  insert into public.reaction_clip_versions
    (clip_id, version, direction, aspect_ratios, duration_seconds,
     direction_hash, created_by)
  values (
    v_clip_id,
    v_version,
    btrim(p_direction),
    p_aspect_ratios,
    p_duration_seconds,
    nano_internal.reaction_clip_hash(p_direction, p_duration_seconds),
    auth.uid()
  )
  returning id into v_id;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'create', 'reaction_clip_version', v_id::text,
    jsonb_build_object('slug', v_slug, 'version', v_version)
  );

  return jsonb_build_object(
    'id', v_id,
    'clip_id', v_clip_id,
    'slug', v_slug,
    'version', v_version,
    'status', 'draft'
  );
end;
$$;

revoke all on function public.create_reaction_clip_draft(
  text, text, text[], integer, text
) from public, anon;
grant execute on function public.create_reaction_clip_draft(
  text, text, text[], integer, text
) to authenticated, service_role;

create or replace function public.publish_reaction_clip_version(p_version_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_version public.reaction_clip_versions;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NM001',
      message = 'Only platform admins can publish reaction clips.';
  end if;

  select * into v_version
  from public.reaction_clip_versions
  where id = p_version_id;

  if v_version.id is null then
    raise exception using
      errcode = 'NM004',
      message = 'That reaction clip version does not exist.';
  end if;
  if v_version.status <> 'draft' then
    raise exception using
      errcode = 'NM004',
      message = 'Only a draft can be published.';
  end if;

  -- The previous direction is retired, not deleted: a clip already generated from
  -- it keeps its provenance and stays explainable.
  update public.reaction_clip_versions
  set status = 'retired',
      retired_at = timezone('utc', now()),
      retired_by = auth.uid()
  where clip_id = v_version.clip_id and status = 'published';

  update public.reaction_clip_versions
  set status = 'published',
      published_at = timezone('utc', now()),
      published_by = auth.uid()
  where id = p_version_id;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'reaction_clip_version',
    p_version_id::text,
    jsonb_build_object('status', 'published', 'version', v_version.version)
  );

  return jsonb_build_object(
    'id', p_version_id,
    'version', v_version.version,
    'status', 'published'
  );
end;
$$;

revoke all on function public.publish_reaction_clip_version(uuid)
  from public, anon;
grant execute on function public.publish_reaction_clip_version(uuid)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Requesting a clip of a reaction
-- ---------------------------------------------------------------------------
-- The caller names a reaction and a shape, never a prompt. The direction comes
-- from the published version, so a clip cannot be made of something nobody
-- approved.
create or replace function public.request_reaction_clip(
  p_slug text,
  p_aspect_ratio text default '1:1'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_clip public.reaction_clips;
  v_version public.reaction_clip_versions;
  v_aspect text := btrim(coalesce(p_aspect_ratio, '1:1'));
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NM001',
      message = 'Only platform admins can request reaction clips.';
  end if;

  select * into v_clip
  from public.reaction_clips
  where slug = btrim(coalesce(p_slug, ''));

  if v_clip.id is null then
    raise exception using
      errcode = 'NM004',
      message = 'That reaction is not in the clip library.';
  end if;

  select * into v_version
  from public.reaction_clip_versions
  where clip_id = v_clip.id and status = 'published';

  if v_version.id is null then
    raise exception using
      errcode = 'NM004',
      message = 'That reaction has no published direction.';
  end if;

  -- Framing is part of the direction, not a rendering detail. A clip written for
  -- a square inline stage is not the same clip in a tall story card.
  if not (v_aspect = any (v_version.aspect_ratios)) then
    raise exception using
      errcode = 'NM009',
      message = 'That reaction is not authored for this shape.';
  end if;

  -- Locale is 'en' and stays 'en': a clip is silent, so a second language would
  -- be a second copy of identical frames. The client's English fallback already
  -- hands it to an Urdu learner.
  return public.request_generated_asset(
    p_kind => 'video',
    p_slot => nano_internal.reaction_clip_slot(v_clip.slug),
    p_prompt => v_version.direction,
    p_prompt_version => 'v' || v_version.version::text,
    p_locale => 'en',
    p_aspect_ratio => v_aspect,
    p_provider_id => null,
    p_feature => 'companion',
    p_school_id => null,
    p_voice_id => null
  );
end;
$$;

comment on function public.request_reaction_clip(text, text) is
  'MED-04 ask for a clip of a published reaction. The direction comes from the '
  'database, the budget from MED-02, and a crashed job is recoverable.';

revoke all on function public.request_reaction_clip(text, text) from public, anon;
grant execute on function public.request_reaction_clip(text, text)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Reuse must not be blocked by a job nobody is running
-- ---------------------------------------------------------------------------
-- Same body as MED-03 with one addition: before an existing row is handed back as
-- a reuse, an abandoned job on it is released. The answer is still `reused: true`
-- — the ask was already charged once and must not be charged twice — but the row
-- comes back as `requested`, which is the worker's signal to pick it up.
create or replace function public.request_generated_asset(
  p_kind public.generated_asset_kind,
  p_slot text,
  p_prompt text,
  p_prompt_version text,
  p_locale text default 'en',
  p_aspect_ratio text default '1:1',
  p_provider_id text default null,
  p_feature text default 'companion',
  p_school_id uuid default null,
  p_voice_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_provider public.generation_providers;
  v_feature text := lower(btrim(coalesce(p_feature, 'companion')));
  v_voice_id text := nullif(lower(btrim(coalesce(p_voice_id, ''))), '');
  v_hash text;
  v_existing public.generated_assets;
  v_id uuid;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NM001',
      message = 'Only platform admins can request generated assets.';
  end if;

  if p_provider_id is null then
    select * into v_provider
    from public.generation_providers
    where kind = p_kind and is_default;
  else
    select * into v_provider
    from public.generation_providers
    where id = p_provider_id;
  end if;

  if v_provider.id is null then
    raise exception using
      errcode = 'NM002',
      message = 'No provider is registered for this asset kind.';
  end if;
  if v_provider.kind <> p_kind then
    raise exception using
      errcode = 'NM002',
      message = 'That provider does not serve this asset kind.';
  end if;
  if not v_provider.is_enabled then
    raise exception using
      errcode = 'NM002',
      message = 'That provider is disabled.';
  end if;

  if v_voice_id is not null then
    if p_kind <> 'voice' then
      raise exception using
        errcode = 'NM002',
        message = 'Only a voice asset may name a voice.';
    end if;
    if not exists (
      select 1 from public.narration_voices
      where id = v_voice_id and is_enabled
    ) then
      raise exception using
        errcode = 'NM002',
        message = 'That voice is not available.';
    end if;
  end if;

  v_hash := nano_internal.generated_asset_hash(
    p_kind, p_slot, p_locale, p_aspect_ratio, p_prompt, p_prompt_version,
    v_voice_id
  );

  -- Reuse is checked before the budget: an ask that costs nothing must never be
  -- refused for being over a limit (MED-02).
  select * into v_existing
  from public.generated_assets
  where kind = p_kind and prompt_hash = v_hash and status <> 'failed';

  if v_existing.id is not null then
    -- An abandoned job is put back in the queue here rather than anywhere else,
    -- because this is the moment somebody has asked for the thing again.
    if nano_internal.release_stale_generation(v_existing.id) then
      return jsonb_build_object(
        'reused', true,
        'asset', nano_internal.generated_asset_json(v_existing.id)
      );
    end if;

    -- If releasing failed it, the row is no longer a reuse candidate and this ask
    -- becomes a fresh job, charged accordingly.
    select * into v_existing
    from public.generated_assets
    where kind = p_kind and prompt_hash = v_hash and status <> 'failed';

    if v_existing.id is not null then
      return jsonb_build_object(
        'reused', true,
        'asset', nano_internal.generated_asset_json(v_existing.id)
      );
    end if;
  end if;

  perform nano_internal.assert_generation_quota(p_kind, v_feature, p_school_id);

  insert into public.generated_assets
    (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
     provider_id, requested_by, feature, school_id, voice_id)
  values
    (p_kind, btrim(p_slot), p_locale, p_aspect_ratio, btrim(p_prompt),
     btrim(p_prompt_version), v_hash, v_provider.id, auth.uid(),
     v_feature, p_school_id, v_voice_id)
  returning id into v_id;

  perform nano_internal.record_generation_usage(
    p_kind, v_feature, p_school_id, 1, 0
  );

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'create', 'generated_asset', v_id::text,
    jsonb_build_object(
      'kind', p_kind,
      'slot', p_slot,
      'locale', p_locale,
      'aspect_ratio', p_aspect_ratio,
      'feature', v_feature,
      'school_id', p_school_id,
      'provider_id', v_provider.id,
      'voice_id', v_voice_id,
      'prompt_version', p_prompt_version,
      'prompt_hash', v_hash
    )
  );

  return jsonb_build_object(
    'reused', false,
    'asset', nano_internal.generated_asset_json(v_id)
  );
end;
$$;

comment on function public.request_generated_asset(
  public.generated_asset_kind, text, text, text, text, text, text, text, uuid, text
) is
  'MED-01/02/03/04 superadmin request. Reuse first, then budget, then the row. '
  'An abandoned job is returned to the queue rather than blocking its slot.';

revoke all on function public.request_generated_asset(
  public.generated_asset_kind, text, text, text, text, text, text, text, uuid, text
) from public, anon;
grant execute on function public.request_generated_asset(
  public.generated_asset_kind, text, text, text, text, text, text, text, uuid, text
) to authenticated, service_role;

-- The asset row a worker sees now mentions the job it is waiting on.
create or replace function nano_internal.generated_asset_json(p_asset_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select jsonb_build_object(
    'id', ga.id,
    'kind', ga.kind,
    'slot', ga.slot,
    'locale', ga.locale,
    'aspect_ratio', ga.aspect_ratio,
    'prompt', ga.prompt,
    'prompt_version', ga.prompt_version,
    'prompt_hash', ga.prompt_hash,
    'provider_id', ga.provider_id,
    'provider_job_id', ga.provider_job_id,
    'voice_id', ga.voice_id,
    'feature', ga.feature,
    'status', ga.status,
    'moderation', ga.moderation,
    'storage_bucket', ga.storage_bucket,
    'storage_path', ga.storage_path,
    'content_type', ga.content_type,
    'byte_size', ga.byte_size,
    'checksum', ga.checksum,
    'cost_micros', ga.cost_micros,
    'attempts_count', ga.attempts_count,
    'error_code', ga.error_code,
    'error_message', ga.error_message,
    'requested_at', ga.requested_at,
    'completed_at', ga.completed_at
  )
  from public.generated_assets ga
  where ga.id = p_asset_id;
$$;

revoke all on function nano_internal.generated_asset_json(uuid) from public, anon;
grant execute on function nano_internal.generated_asset_json(uuid)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- What a client may read
-- ---------------------------------------------------------------------------
-- Which reactions currently have an approved clip, and where the file is.
--
-- Unlike MED-03's narration read, this returns no authored text at all. A caption
-- is the product and a learner needs it; a clip direction is a prompt, and a
-- prompt is authoring detail that never leaves the administration surface.
create or replace function public.list_reaction_clips()
returns table (
  slug text,
  mode text,
  mood text,
  slot text,
  version integer,
  aspect_ratio text,
  duration_seconds integer,
  storage_bucket text,
  storage_path text,
  content_type text,
  byte_size bigint,
  checksum text
)
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select
    rc.slug,
    rc.mode,
    rc.mood,
    nano_internal.reaction_clip_slot(rc.slug) as slot,
    rcv.version,
    ga.aspect_ratio,
    rcv.duration_seconds,
    ga.storage_bucket,
    ga.storage_path,
    ga.content_type,
    ga.byte_size,
    ga.checksum
  from public.reaction_clips rc
  join public.reaction_clip_versions rcv
    on rcv.clip_id = rc.id and rcv.status = 'published'
  -- A clip only counts when it was made from *this* direction. An older version's
  -- footage is not offered as a near-enough match.
  join public.generated_assets ga
    on ga.kind = 'video'
   and ga.slot = nano_internal.reaction_clip_slot(rc.slug)
   and ga.prompt_version = 'v' || rcv.version::text
   and ga.status = 'ready'
   and ga.moderation = 'approved'
  order by rc.slug, ga.aspect_ratio;
$$;

comment on function public.list_reaction_clips() is
  'MED-04 client read side: the reactions that actually have an approved clip. '
  'No direction, no provider, no cost — a clip is an enhancement, not content.';

revoke all on function public.list_reaction_clips() from public, anon;
grant execute on function public.list_reaction_clips() to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Seed: the reactions worth a clip first
-- ---------------------------------------------------------------------------
-- Celebration is the one the local manifest already reaches, so it is the clip
-- that changes anything today. The other two are in the library so the reusable
-- part is real rather than promised: approving either makes that reaction move,
-- with no app release, because availability is read per reaction slot.
insert into public.reaction_clips (slug, mode, mood, notes)
values
  ('celebration_celebration', 'celebration', 'celebration',
   'The milestone moment. The only reaction the local manifest already treats as clip-worthy.'),
  ('guide_greeting', 'guide', 'greeting',
   'First-run warmth. Optional: local animation is the shipped fallback.'),
  ('quizCoach_celebration', 'quizCoach', 'celebration',
   'Passing a quiz without becoming full Celebration Nori.')
on conflict (slug) do nothing;

insert into public.reaction_clip_versions
  (clip_id, version, status, direction, aspect_ratios, duration_seconds,
   direction_hash, published_at)
select
  rc.id,
  1,
  'published',
  seed.direction,
  seed.aspect_ratios,
  seed.duration_seconds,
  nano_internal.reaction_clip_hash(seed.direction, seed.duration_seconds),
  timezone('utc', now())
from (
  values
    ('celebration_celebration',
     'A small round friendly companion with soft rounded edges does a happy hop '
     'and a gentle spin, confetti drifting slowly behind it, warm daylight '
     'palette, calm and unhurried, plain uncluttered background, no text, no '
     'people, loopable.',
     array['1:1', '9:16'],
     4),
    ('guide_greeting',
     'A small round friendly companion with soft rounded edges waves once and '
     'settles, a slow blink, warm daylight palette, calm and unhurried, plain '
     'uncluttered background, no text, no people, loopable.',
     array['1:1'],
     3),
    ('quizCoach_celebration',
     'A small round friendly companion with soft rounded edges gives a single '
     'encouraging nod and a quiet thumbs up, warm daylight palette, calm and '
     'unhurried, plain uncluttered background, no text, no people, loopable.',
     array['1:1'],
     3)
) as seed(slug, direction, aspect_ratios, duration_seconds)
join public.reaction_clips rc on rc.slug = seed.slug
where not exists (
  select 1 from public.reaction_clip_versions v where v.clip_id = rc.id
);
