-- MED-09 adversarial checks on the character sheet.
--
-- The sheet is the only thing standing between "we generate poses" and "we
-- accumulate a family of similar-looking strangers". These probe the ways it
-- could quietly stop doing that job: two current sheets, a sheet a learner can
-- rewrite, a reviewer who cannot read the thing they are reviewing against.
--
-- Run with: psql "$DEV_DB_URL" -v ON_ERROR_STOP=1 -f med09_pose_coverage.sql

begin;

do $$
declare
  v_admin uuid;
  v_learner uuid;
  v_count int;
  v_version text;
  v_ref uuid;
begin
  -- -------------------------------------------------------------------------
  -- There is exactly one current sheet, and it points at approved art
  -- -------------------------------------------------------------------------
  select count(*) into v_count
  from public.companion_character_sheet
  where is_current;

  if v_count <> 1 then
    raise exception 'FAIL: expected exactly one current character sheet, found %', v_count;
  end if;

  select version, reference_asset_id into v_version, v_ref
  from public.companion_character_sheet
  where is_current;

  if v_ref is null then
    raise exception 'FAIL: the current sheet names no reference picture';
  end if;

  -- A sheet whose reference was never approved is a sheet describing something
  -- no learner has seen, which makes every comparison against it a guess.
  if not exists (
    select 1
    from public.generated_assets
    where id = v_ref
      and kind = 'image'
      and moderation = 'approved'
  ) then
    raise exception 'FAIL: the sheet references art that is not approved image';
  end if;

  -- -------------------------------------------------------------------------
  -- A second current sheet is impossible
  -- -------------------------------------------------------------------------
  begin
    insert into public.companion_character_sheet (version, summary, is_current)
    values ('v-conflict', 'a rival definition of Nori', true);
    raise exception 'FAIL: two sheets were allowed to be current at once';
  exception
    when unique_violation then
      null; -- the index held
  end;

  -- -------------------------------------------------------------------------
  -- The sheet is useless if the reviewer cannot read it
  -- -------------------------------------------------------------------------
  select id into v_admin
  from public.profiles
  where role = 'superadmin'
  limit 1;

  select id into v_learner
  from public.profiles
  where role in ('junior_student', 'senior_student', 'independent_student')
  limit 1;

  if v_admin is null then
    raise exception 'FAIL: no platform admin fixture to test with';
  end if;

  reset role;
  set local role authenticated;
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text,
    true
  );

  if (select count(*) from public.current_character_sheet()) <> 1 then
    raise exception 'FAIL: a reviewer cannot read the sheet they review against';
  end if;

  -- -------------------------------------------------------------------------
  -- A learner may read it and may not rewrite it
  -- -------------------------------------------------------------------------
  if v_learner is not null then
    reset role;
    set local role authenticated;
    perform set_config(
      'request.jwt.claims',
      json_build_object('sub', v_learner, 'role', 'authenticated')::text,
      true
    );

    -- Reading is harmless: it is a description of a cartoon.
    if (select count(*) from public.companion_character_sheet) < 1 then
      raise exception 'FAIL: the sheet is hidden from signed-in users';
    end if;

    begin
      update public.companion_character_sheet
      set summary = 'Nori is a shark now'
      where version = v_version;

      -- RLS filters rather than raising, so an update that changed nothing is
      -- the pass. An update that touched a row is the failure.
      get diagnostics v_count = row_count;
      if v_count > 0 then
        raise exception 'FAIL: a learner rewrote the character sheet';
      end if;
    exception
      when insufficient_privilege then
        null; -- also acceptable
    end;
  end if;

  reset role;
  raise notice 'PASS: MED-09 character sheet holds (% current)', v_version;
end;
$$;

rollback;
