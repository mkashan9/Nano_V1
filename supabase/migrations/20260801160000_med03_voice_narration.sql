-- MED-03: the Learning Guide's voice.
--
-- Three things arrive here, and the order matters.
--
-- 1. A **line** is authored content, not a prompt. `narration_lines` and
--    `narration_line_versions` follow the QZ-01 pattern: a stable slug, a
--    versioned body with English and optional Urdu, draft → published → retired,
--    and published rows immutable. That is what makes "the audio says what the
--    caption says" checkable rather than hopeful.
--
-- 2. A **voice** is registered, not named in a request. `narration_voices` says
--    which provider speaks, under which provider-side name, and in which
--    languages. The Learning Guide is Aoede (handbook 10.1), and a request that
--    names an unknown or disabled voice is refused.
--
-- 3. The **voice is part of the reuse hash**, because the same sentence in a
--    different voice is a different recording. The aspect ratio, meanwhile, is
--    dropped from the hash for voice, where it means nothing — otherwise a caller
--    passing a different harmless default would pay for the same audio twice.
--
-- One rule is worth stating loudly: a line containing a placeholder such as
-- `{name}` is never pre-generated. The companion's name belongs to the learner,
-- and a recording would say somebody else's. Those lines stay caption-only,
-- which the app already handles because captions never depended on audio.

-- ---------------------------------------------------------------------------
-- Voices
-- ---------------------------------------------------------------------------
create table if not exists public.narration_voices (
  id text primary key,
  provider_id text not null references public.generation_providers (id),
  -- What the provider calls it. Ours is 'aoede'; theirs is 'Aoede'.
  provider_voice_name text not null check (btrim(provider_voice_name) <> ''),
  display_name text not null check (btrim(display_name) <> ''),
  style text not null default '',
  locales text[] not null default array['en', 'ur'],
  is_default boolean not null default false,
  is_enabled boolean not null default true,
  notes text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint narration_voices_locales_known check (
    locales <@ array['en', 'ur'] and array_length(locales, 1) > 0
  )
);

comment on table public.narration_voices is
  'MED-03 registry of voices the Learning Guide may speak in. A request names a '
  'voice from here or takes the default; it never names a provider voice string.';

-- Exactly one default voice: every row that could match has the same value, so a
-- unique index on it allows one.
create unique index if not exists narration_voices_default_idx
  on public.narration_voices (is_default)
  where is_default;

drop trigger if exists narration_voices_set_updated_at on public.narration_voices;
create trigger narration_voices_set_updated_at
  before update on public.narration_voices
  for each row execute function public.set_updated_at();

-- The chosen provider. Gemini's TTS models expose Aoede as a prebuilt voice and
-- return raw 24 kHz PCM, which the adapter wraps as WAV.
insert into public.generation_providers
  (id, kind, is_enabled, is_default, requires_key, notes)
values (
  'gemini_voice_aoede',
  'voice',
  true,
  false,
  true,
  'Learning Guide voice Aoede; VOICE_PROVIDER_API_KEY in Edge Function env.'
)
on conflict (id) do nothing;

-- One default per kind is a partial unique index that is checked row by row, so
-- the old default steps down in its own statement before the new one steps up.
update public.generation_providers
set is_default = false
where kind = 'voice' and id <> 'gemini_voice_aoede';

update public.generation_providers
set is_default = true
where id = 'gemini_voice_aoede';

insert into public.narration_voices
  (id, provider_id, provider_voice_name, display_name, style, locales,
   is_default, is_enabled, notes)
values (
  'aoede',
  'gemini_voice_aoede',
  'Aoede',
  'Aoede Learning Guide',
  'breezy, warm, unhurried',
  array['en', 'ur'],
  true,
  true,
  'Handbook 10.1: one narration style across every companion variant.'
)
on conflict (id) do nothing;

alter table public.narration_voices enable row level security;

drop policy if exists narration_voices_select on public.narration_voices;
create policy narration_voices_select on public.narration_voices
  for select to authenticated
  using (nano_internal.is_platform_admin());

revoke insert, update, delete on public.narration_voices from authenticated;

-- Which voice spoke a recording. Null for art, and for a voice asset requested
-- before this module existed.
alter table public.generated_assets
  add column if not exists voice_id text references public.narration_voices (id);

comment on column public.generated_assets.voice_id is
  'MED-03 the registered voice a recording was made in. Part of the reuse hash, '
  'so the same sentence in another voice is another recording.';

-- ---------------------------------------------------------------------------
-- Hashing: voice in, aspect ratio out
-- ---------------------------------------------------------------------------
create or replace function nano_internal.generated_asset_hash(
  p_kind public.generated_asset_kind,
  p_slot text,
  p_locale text,
  p_aspect_ratio text,
  p_prompt text,
  p_prompt_version text,
  p_voice_id text
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
        p_kind::text,
        lower(btrim(coalesce(p_slot, ''))),
        lower(btrim(coalesce(p_locale, ''))),
        -- A recording has no aspect ratio; including one would let two callers
        -- with different harmless defaults pay for the same audio twice.
        case when p_kind = 'voice' then '' else btrim(coalesce(p_aspect_ratio, '')) end,
        btrim(coalesce(p_prompt_version, '')),
        lower(btrim(coalesce(p_voice_id, ''))),
        nano_internal.normalize_generation_prompt(p_prompt)
      ),
      'sha256'
    ),
    'hex'
  );
$$;

revoke all on function nano_internal.generated_asset_hash(
  public.generated_asset_kind, text, text, text, text, text, text
) from public, anon;
grant execute on function nano_internal.generated_asset_hash(
  public.generated_asset_kind, text, text, text, text, text, text
) to authenticated, service_role;

-- The six-argument form stays as a voiceless wrapper, so every MED-01 and MED-02
-- caller and test keeps working and image hashes do not move.
create or replace function nano_internal.generated_asset_hash(
  p_kind public.generated_asset_kind,
  p_slot text,
  p_locale text,
  p_aspect_ratio text,
  p_prompt text,
  p_prompt_version text
)
returns text
language sql
immutable
set search_path = pg_catalog, public, nano_internal
as $$
  select nano_internal.generated_asset_hash(
    p_kind, p_slot, p_locale, p_aspect_ratio, p_prompt, p_prompt_version, null
  );
$$;

-- ---------------------------------------------------------------------------
-- Where a recording lives
-- ---------------------------------------------------------------------------
-- One function, so the slot a request writes and the slot a client looks up can
-- never disagree.
create or replace function nano_internal.narration_slot(p_slug text)
returns text
language sql
immutable
set search_path = pg_catalog
as $$
  select 'narration_' || lower(btrim(coalesce(p_slug, '')));
$$;

revoke all on function nano_internal.narration_slot(text) from public, anon;
grant execute on function nano_internal.narration_slot(text)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Request, now aware of a voice
-- ---------------------------------------------------------------------------
drop function if exists public.request_generated_asset(
  public.generated_asset_kind, text, text, text, text, text, text, text, uuid
);

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

  -- A voice belongs to a recording and nothing else. Silence about a mismatch
  -- would leave an image row claiming a voice, which the hash would then honour.
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
    return jsonb_build_object(
      'reused', true,
      'asset', nano_internal.generated_asset_json(v_existing.id)
    );
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
  'MED-01/02/03 superadmin request. Reuse first, then budget, then the row. A '
  'voice asset also carries the registered voice it was recorded in.';

revoke all on function public.request_generated_asset(
  public.generated_asset_kind, text, text, text, text, text, text, text, uuid, text
) from public, anon;
grant execute on function public.request_generated_asset(
  public.generated_asset_kind, text, text, text, text, text, text, text, uuid, text
) to authenticated, service_role;

-- The asset row a worker and an admin see now mentions the voice too.
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
-- Authored lines
-- ---------------------------------------------------------------------------
create table if not exists public.narration_lines (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9][a-z0-9_.-]{0,63}$'),
  -- Where the line is spoken. `companion` matches a CompanionScript id exactly,
  -- which is what keeps the recording and the local caption in step.
  surface text not null default 'companion'
    check (surface in ('companion', 'onboarding', 'learning')),
  notes text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.narration_lines is
  'MED-03 stable identity of a spoken line. For the companion the slug is the '
  'CompanionScript id, so the local caption and the recording cannot drift.';

create table if not exists public.narration_line_versions (
  id uuid primary key default gen_random_uuid(),
  line_id uuid not null references public.narration_lines (id) on delete cascade,
  version integer not null check (version >= 1),
  status text not null default 'draft'
    check (status in ('draft', 'published', 'retired')),
  text text not null check (btrim(text) <> ''),
  text_ur text,
  locale_policy text not null default 'both'
    check (locale_policy in ('en', 'ur', 'both')),
  text_hash text not null,
  created_by uuid references public.profiles (id),
  published_at timestamptz,
  published_by uuid references public.profiles (id),
  retired_at timestamptz,
  retired_by uuid references public.profiles (id),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint narration_line_versions_unique unique (line_id, version),
  constraint narration_line_versions_ur_present check (
    locale_policy <> 'both' or (text_ur is not null and btrim(text_ur) <> '')
  )
);

comment on table public.narration_line_versions is
  'MED-03 versioned wording. A published version is immutable, so a recording '
  'made from version 2 can never quietly become a recording of different words.';

-- One published version per line: the app asks for a line, not for a version.
create unique index if not exists narration_line_versions_published_idx
  on public.narration_line_versions (line_id)
  where status = 'published';

drop trigger if exists narration_line_versions_set_updated_at
  on public.narration_line_versions;
create trigger narration_line_versions_set_updated_at
  before update on public.narration_line_versions
  for each row execute function public.set_updated_at();

create or replace function nano_internal.narration_text_hash(
  p_text text,
  p_text_ur text
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
        nano_internal.normalize_generation_prompt(p_text),
        nano_internal.normalize_generation_prompt(coalesce(p_text_ur, ''))
      ),
      'sha256'
    ),
    'hex'
  );
$$;

revoke all on function nano_internal.narration_text_hash(text, text)
  from public, anon;
grant execute on function nano_internal.narration_text_hash(text, text)
  to authenticated, service_role;

-- Published wording cannot be edited. Anything else would make an existing
-- recording a lie, and the recording is what a child hears.
create or replace function nano_internal.narration_version_guard()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if old.status = 'published' and (
    new.text is distinct from old.text
    or new.text_ur is distinct from old.text_ur
    or new.locale_policy is distinct from old.locale_policy
    or new.version is distinct from old.version
    or new.line_id is distinct from old.line_id
  ) then
    raise exception using
      errcode = 'NM008',
      message = 'A published narration line cannot be edited. Publish a new version.';
  end if;
  return new;
end;
$$;

drop trigger if exists narration_line_versions_guard
  on public.narration_line_versions;
create trigger narration_line_versions_guard
  before update on public.narration_line_versions
  for each row execute function nano_internal.narration_version_guard();

alter table public.narration_lines enable row level security;
alter table public.narration_line_versions enable row level security;

drop policy if exists narration_lines_select on public.narration_lines;
create policy narration_lines_select on public.narration_lines
  for select to authenticated
  using (nano_internal.is_platform_admin());

drop policy if exists narration_line_versions_select
  on public.narration_line_versions;
create policy narration_line_versions_select on public.narration_line_versions
  for select to authenticated
  using (nano_internal.is_platform_admin());

revoke insert, update, delete on public.narration_lines from authenticated;
revoke insert, update, delete on public.narration_line_versions from authenticated;

-- ---------------------------------------------------------------------------
-- Authoring
-- ---------------------------------------------------------------------------
create or replace function public.create_narration_line_draft(
  p_slug text,
  p_text text,
  p_text_ur text default null,
  p_locale_policy text default 'both',
  p_surface text default 'companion',
  p_notes text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_line_id uuid;
  v_version integer;
  v_id uuid;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NM001',
      message = 'Only platform admins can author narration lines.';
  end if;

  insert into public.narration_lines (slug, surface, notes)
  values (lower(btrim(p_slug)), p_surface, p_notes)
  on conflict (slug) do update
    set notes = case
          when btrim(excluded.notes) = '' then public.narration_lines.notes
          else excluded.notes
        end
  returning id into v_line_id;

  select coalesce(max(version), 0) + 1 into v_version
  from public.narration_line_versions
  where line_id = v_line_id;

  insert into public.narration_line_versions
    (line_id, version, text, text_ur, locale_policy, text_hash, created_by)
  values (
    v_line_id,
    v_version,
    btrim(p_text),
    nullif(btrim(coalesce(p_text_ur, '')), ''),
    p_locale_policy,
    nano_internal.narration_text_hash(p_text, p_text_ur),
    auth.uid()
  )
  returning id into v_id;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'create', 'narration_line_version', v_id::text,
    jsonb_build_object('slug', lower(btrim(p_slug)), 'version', v_version)
  );

  return jsonb_build_object(
    'id', v_id,
    'line_id', v_line_id,
    'slug', lower(btrim(p_slug)),
    'version', v_version,
    'status', 'draft'
  );
end;
$$;

revoke all on function public.create_narration_line_draft(
  text, text, text, text, text, text
) from public, anon;
grant execute on function public.create_narration_line_draft(
  text, text, text, text, text, text
) to authenticated, service_role;

create or replace function public.publish_narration_line_version(
  p_version_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_version public.narration_line_versions;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NM001',
      message = 'Only platform admins can publish narration lines.';
  end if;

  select * into v_version
  from public.narration_line_versions
  where id = p_version_id;

  if v_version.id is null then
    raise exception using
      errcode = 'NM004',
      message = 'That narration version does not exist.';
  end if;
  if v_version.status <> 'draft' then
    raise exception using
      errcode = 'NM004',
      message = 'Only a draft can be published.';
  end if;

  -- The previous wording is retired, not deleted: a recording already made from
  -- it keeps its provenance and stays explainable.
  update public.narration_line_versions
  set status = 'retired',
      retired_at = timezone('utc', now()),
      retired_by = auth.uid()
  where line_id = v_version.line_id and status = 'published';

  update public.narration_line_versions
  set status = 'published',
      published_at = timezone('utc', now()),
      published_by = auth.uid()
  where id = p_version_id;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(), 'superadmin', 'update', 'narration_line_version',
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

revoke all on function public.publish_narration_line_version(uuid)
  from public, anon;
grant execute on function public.publish_narration_line_version(uuid)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Requesting a recording of a line
-- ---------------------------------------------------------------------------
-- The caller names a line and a language, never a prompt. The words come from the
-- published version, so a recording cannot be made of text nobody approved.
create or replace function public.request_narration_line(
  p_slug text,
  p_locale text default 'en',
  p_voice_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_line public.narration_lines;
  v_version public.narration_line_versions;
  v_voice public.narration_voices;
  v_text text;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NM001',
      message = 'Only platform admins can request narration.';
  end if;

  select * into v_line
  from public.narration_lines
  where slug = lower(btrim(p_slug));

  if v_line.id is null then
    raise exception using
      errcode = 'NM004',
      message = 'That narration line does not exist.';
  end if;

  select * into v_version
  from public.narration_line_versions
  where line_id = v_line.id and status = 'published';

  if v_version.id is null then
    raise exception using
      errcode = 'NM004',
      message = 'That narration line has no published wording.';
  end if;

  if p_voice_id is null then
    select * into v_voice from public.narration_voices where is_default;
  else
    select * into v_voice
    from public.narration_voices
    where id = lower(btrim(p_voice_id));
  end if;

  if v_voice.id is null or not v_voice.is_enabled then
    raise exception using
      errcode = 'NM002',
      message = 'That voice is not available.';
  end if;
  if not (p_locale = any (v_voice.locales)) then
    raise exception using
      errcode = 'NM002',
      message = 'That voice does not speak this language.';
  end if;

  if v_version.locale_policy <> 'both' and v_version.locale_policy <> p_locale then
    raise exception using
      errcode = 'NM007',
      message = 'That line is not authored for this language.';
  end if;

  v_text := case
    when p_locale = 'ur' then v_version.text_ur
    else v_version.text
  end;

  if coalesce(btrim(v_text), '') = '' then
    raise exception using
      errcode = 'NM007',
      message = 'That line has no wording in this language.';
  end if;

  -- The companion's name belongs to the learner. A recording containing it would
  -- greet somebody else, so a placeholder line stays caption-only forever.
  if v_text ~ '\{[a-zA-Z_]+\}' then
    raise exception using
      errcode = 'NM007',
      message = 'A line with a placeholder cannot be pre-recorded.';
  end if;

  return public.request_generated_asset(
    p_kind => 'voice',
    p_slot => nano_internal.narration_slot(v_line.slug),
    p_prompt => v_text,
    p_prompt_version => 'v' || v_version.version::text,
    p_locale => p_locale,
    p_aspect_ratio => '1:1',
    p_provider_id => v_voice.provider_id,
    p_feature => v_line.surface,
    p_school_id => null,
    p_voice_id => v_voice.id
  );
end;
$$;

comment on function public.request_narration_line(text, text, text) is
  'MED-03 ask for a recording of a published line. The words come from the '
  'database, the budget from MED-02, and the voice from the registry.';

revoke all on function public.request_narration_line(text, text, text)
  from public, anon;
grant execute on function public.request_narration_line(text, text, text)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- What a client may read
-- ---------------------------------------------------------------------------
-- Published wording in one language, plus the recording when one exists and has
-- been approved. Nothing about prompts, providers, or cost.
create or replace function public.list_narration_lines(
  p_locale text default 'en',
  p_surface text default null
)
returns table (
  slug text,
  surface text,
  version integer,
  locale text,
  -- Not `text`: an output column sharing a name with a type and with a column on
  -- the table being read is a needless ambiguity for every future reader.
  line_text text,
  voice_id text,
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
    nl.slug,
    nl.surface,
    nlv.version,
    p_locale as locale,
    case when p_locale = 'ur' then coalesce(nlv.text_ur, nlv.text) else nlv.text end
      as line_text,
    ga.voice_id,
    ga.storage_bucket,
    ga.storage_path,
    ga.content_type,
    ga.byte_size,
    ga.checksum
  from public.narration_lines nl
  join public.narration_line_versions nlv
    on nlv.line_id = nl.id and nlv.status = 'published'
  -- A recording only counts when it was made from *this* wording, in *this*
  -- language. An older version's audio is not offered as a near-enough match.
  left join public.generated_assets ga
    on ga.kind = 'voice'
   and ga.slot = nano_internal.narration_slot(nl.slug)
   and ga.locale = p_locale
   and ga.prompt_version = 'v' || nlv.version::text
   and ga.status = 'ready'
   and ga.moderation = 'approved'
  where (p_surface is null or nl.surface = p_surface)
    and (nlv.locale_policy = 'both' or nlv.locale_policy = p_locale)
  order by nl.slug;
$$;

comment on function public.list_narration_lines(text, text) is
  'MED-03 client read side: published wording for one language, and the approved '
  'recording of that exact wording when there is one. Audio is always optional.';

revoke all on function public.list_narration_lines(text, text) from public, anon;
grant execute on function public.list_narration_lines(text, text)
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Seed: the nine companion lines, matching CompanionScriptBook ids exactly
-- ---------------------------------------------------------------------------
-- The slugs are the Dart script ids on purpose. The local book stays the offline
-- caption source; these rows are what may be recorded, and the checked-in tests
-- assert the two lists are the same.
insert into public.narration_lines (slug, surface, notes)
values
  ('greeting-1', 'companion', 'Contains {name}; caption-only by design.'),
  ('greeting-2', 'companion', ''),
  ('idle-1', 'companion', ''),
  ('point-1', 'companion', ''),
  ('point-2', 'companion', ''),
  ('thinking-1', 'companion', ''),
  ('retry-1', 'companion', ''),
  ('celebration-1', 'companion', ''),
  ('celebration-2', 'companion', '')
on conflict (slug) do nothing;

insert into public.narration_line_versions
  (line_id, version, status, text, text_ur, text_hash, published_at)
select
  nl.id,
  1,
  'published',
  seed.text,
  seed.text_ur,
  nano_internal.narration_text_hash(seed.text, seed.text_ur),
  timezone('utc', now())
from (
  values
    ('greeting-1',
     'Hello! {name} is here whenever you are ready.',
     'سلام! {name} آپ کے ساتھ ہے۔'),
    ('greeting-2',
     'Good to see you again.',
     'آپ کو دوبارہ دیکھ کر خوشی ہوئی۔'),
    ('idle-1',
     'Take your time.',
     'آرام سے کریں۔'),
    ('point-1',
     'Start here.',
     'یہاں سے شروع کریں۔'),
    ('point-2',
     'This one is next.',
     'اگلا یہ ہے۔'),
    ('thinking-1',
     'Read it once more, then choose.',
     'ایک بار پھر پڑھیں، پھر انتخاب کریں۔'),
    ('retry-1',
     'Some of these need another look. We can try again.',
     'کچھ سوال دوبارہ دیکھنے ہیں۔ ہم پھر کوشش کریں گے۔'),
    ('celebration-1',
     'Nicely done!',
     'بہت خوب!'),
    ('celebration-2',
     'That was good work.',
     'یہ اچھا کام تھا۔')
) as seed(slug, text, text_ur)
join public.narration_lines nl on nl.slug = seed.slug
where not exists (
  select 1 from public.narration_line_versions v where v.line_id = nl.id
);
