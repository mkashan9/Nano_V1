-- MED-11 adversarial checks on narration coverage.
--
-- Coverage is the kind of property that is true on the day it ships and quietly
-- false six modules later, when somebody adds a line to the script book and
-- nobody records it. These probes are the thing that notices.
--
-- Run with: psql "$DEV_DB_URL" -v ON_ERROR_STOP=1 -f med11_narration_coverage.sql

begin;

do $$
declare
  v_missing text;
  v_count int;
  v_admin uuid;
  v_learner uuid;
begin
  -- -------------------------------------------------------------------------
  -- Every published, non-personalised line has a recording in both languages
  -- -------------------------------------------------------------------------
  -- Personalised lines are excluded by ADR-0008 and not by omission: a
  -- recording of "Hello, {name}" would say one child's companion name to every
  -- other child, so those lines are caption-only forever.
  select string_agg(missing, ', ')
  into v_missing
  from (
    select l.slug || '/' || loc.locale as missing
    from public.narration_lines l
    join public.narration_line_versions v
      on v.line_id = l.id and v.status = 'published'
    cross join (values ('en'), ('ur')) as loc(locale)
    where v.text not like '%{%'
      and coalesce(v.text_ur, '') not like '%{%'
      and not exists (
        select 1
        from public.generated_assets a
        where a.kind = 'voice'
          and a.slot = 'narration_' || l.slug
          and a.locale = loc.locale
          and a.moderation <> 'rejected'
      )
  ) gaps;

  if v_missing is not null then
    raise exception 'FAIL: no recording requested for %', v_missing;
  end if;

  -- -------------------------------------------------------------------------
  -- A personalised line was never recorded by accident
  -- -------------------------------------------------------------------------
  select count(*)
  into v_count
  from public.narration_lines l
  join public.narration_line_versions v
    on v.line_id = l.id and v.status = 'published'
  join public.generated_assets a
    on a.kind = 'voice'
   and a.slot = 'narration_' || l.slug
   and a.moderation = 'approved'
  where v.text like '%{%' or coalesce(v.text_ur, '') like '%{%';

  if v_count > 0 then
    raise exception
      'FAIL: % personalised line(s) have an approved recording (ADR-0008)',
      v_count;
  end if;

  -- -------------------------------------------------------------------------
  -- Every recording is in the cast voice
  -- -------------------------------------------------------------------------
  -- A line recorded by a superseded voice is worse than a line with no
  -- recording: the companion changes voice mid-session and nobody can say why.
  select count(*)
  into v_count
  from public.generated_assets a
  where a.kind = 'voice'
    and a.moderation <> 'rejected'
    and a.provider_id <> (
      select provider_id from public.narration_voices where is_default
    );

  if v_count > 0 then
    raise exception 'FAIL: % recording(s) are not from the cast provider', v_count;
  end if;

  -- -------------------------------------------------------------------------
  -- Urdu audio is never an English file wearing an Urdu label
  -- -------------------------------------------------------------------------
  -- Strict locale match is the rule the client enforces; this is the same rule
  -- checked from the other side. Two locales sharing one storage object would
  -- mean a child who chose Urdu hears English.
  select count(*)
  into v_count
  from (
    select storage_path
    from public.generated_assets
    where kind = 'voice'
      and moderation <> 'rejected'
      and storage_path is not null
    group by storage_path
    having count(distinct locale) > 1
  ) shared;

  if v_count > 0 then
    raise exception 'FAIL: % audio file(s) are shared across locales', v_count;
  end if;

  -- -------------------------------------------------------------------------
  -- Every celebration mode has a clip
  -- -------------------------------------------------------------------------
  -- Derived from the published clip library rather than from a list of modes,
  -- so adding a celebration reaction is enough to make this fail until it is
  -- rendered. A mode with direction written and no clip behind it is the
  -- failure that looks fine in the database and shows a still picture in the
  -- app.
  select string_agg(c.slug, ', ')
  into v_missing
  from public.reaction_clips c
  join public.reaction_clip_versions v
    on v.clip_id = c.id and v.status = 'published'
  where c.mood = 'celebration'
    and not exists (
      select 1
      from public.generated_assets a
      where a.kind = 'video'
        and a.slot = c.slug || '_shortClip'
        and a.moderation <> 'rejected'
    );

  if v_missing is not null then
    raise exception 'FAIL: no clip rendered for %', v_missing;
  end if;

  -- -------------------------------------------------------------------------
  -- No clip came from the fallback compositor
  -- -------------------------------------------------------------------------
  -- The fallback exists so a render never hard-fails, not so it can quietly
  -- become the source of the art. Its output was rejected twice by the owner
  -- in MED-06 for looking fake, and it costs 15,000 micros against Wan's zero.
  -- A fallback render that nobody notices is the expensive, ugly outcome.
  select count(*)
  into v_count
  from public.generated_assets
  where kind = 'video'
    and moderation = 'approved'
    and provider_id = 'json2video_compose';

  if v_count > 0 then
    raise exception
      'FAIL: % approved clip(s) came from the fallback compositor', v_count;
  end if;

  -- -------------------------------------------------------------------------
  -- Nothing reaches a learner without passing review
  -- -------------------------------------------------------------------------
  select id into v_learner
  from public.profiles
  where role in ('junior_student', 'senior_student', 'independent_student')
  limit 1;

  if v_learner is not null then
    reset role;
    set local role authenticated;
    perform set_config(
      'request.jwt.claims',
      json_build_object('sub', v_learner, 'role', 'authenticated')::text,
      true
    );

    select count(*) into v_count
    from public.list_generated_assets()
    where moderation <> 'approved';

    if v_count > 0 then
      raise exception 'FAIL: a learner can see % unapproved asset(s)', v_count;
    end if;

    reset role;
  end if;

  -- -------------------------------------------------------------------------
  -- The spend is visible and small
  -- -------------------------------------------------------------------------
  select coalesce(sum(cost_micros), 0) into v_count
  from public.generated_assets
  where kind = 'voice';

  raise notice 'PASS: narration coverage holds; voice spend so far % micros', v_count;
end;
$$;

rollback;
