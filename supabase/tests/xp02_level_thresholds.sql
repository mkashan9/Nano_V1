-- XP-02: thresholds are server-owned; ledger totals reconcile to xp_progress.

begin;

do $$
declare
  v_count int;
  v_prog jsonb;
  v_level int;
begin
  if not exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'level_rules'
  ) then
    raise exception 'level_rules missing';
  end if;

  if not exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'xp_progress'
  ) then
    raise exception 'xp_progress missing';
  end if;

  select count(*) into v_count from public.level_rules;
  if v_count < 2 then
    raise exception 'level_rules needs at least two levels, found %', v_count;
  end if;

  -- Flat seed: 0 XP is level 1, 250 is level 2, 560 is level 3.
  v_prog := nano_internal.level_progress_for_xp(0);
  if (v_prog ->> 'level')::int <> 1 then
    raise exception '0 XP must be level 1, got %', v_prog;
  end if;

  v_prog := nano_internal.level_progress_for_xp(250);
  if (v_prog ->> 'level')::int <> 2
     or (v_prog ->> 'xp_into_level')::int <> 0 then
    raise exception '250 XP must be exactly level 2, got %', v_prog;
  end if;

  v_prog := nano_internal.level_progress_for_xp(560);
  if (v_prog ->> 'level')::int <> 3
     or (v_prog ->> 'xp_into_level')::int <> 60
     or (v_prog ->> 'xp_to_next')::int <> 190 then
    raise exception '560 XP must be level 3 with 60/190, got %', v_prog;
  end if;

  -- Every xp_progress row must match a fresh derivation from the ledger.
  select count(*) into v_count
  from public.xp_progress p
  where p.level is distinct from (
          nano_internal.level_progress_for_xp(p.total_xp) ->> 'level'
        )::int
     or p.total_xp is distinct from (
          select coalesce(sum(l.amount), 0)
          from public.xp_ledger l
          where l.user_id = p.user_id
        );

  if v_count <> 0 then
    raise exception
      'xp_progress does not reconcile to the ledger for % learner(s)',
      v_count;
  end if;

  -- Learners must not be able to write level_rules or xp_progress.
  if has_table_privilege('authenticated', 'public.level_rules', 'insert')
     or has_table_privilege('authenticated', 'public.xp_progress', 'insert')
     or has_table_privilege('authenticated', 'public.xp_progress', 'update')
  then
    raise exception 'authenticated must not write level_rules or xp_progress';
  end if;

  raise notice 'xp02_level_thresholds: ok';
end;
$$;

rollback;
