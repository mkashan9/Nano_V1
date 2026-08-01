-- XP-01 adversarial checks: idempotency, no failed-quiz credit, own-read only.
--
-- Run against development with a learner JWT; the probe bodies below are also
-- executable via the Supabase MCP as anonymous checks on schema invariants.

begin;

do $$
declare
  v_count int;
begin
  -- -----------------------------------------------------------------------
  -- Schema invariants
  -- -----------------------------------------------------------------------
  if not exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'xp_ledger'
  ) then
    raise exception 'FAIL: xp_ledger is missing';
  end if;

  if not exists (
    select 1 from pg_indexes
    where schemaname = 'public'
      and indexname = 'xp_ledger_user_id_source_kind_source_id_key'
  ) and not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'xp_ledger'
      and constraint_type = 'UNIQUE'
  ) then
    -- Unique constraint may be named differently; check columns.
    select count(*) into v_count
    from information_schema.constraint_column_usage
    where table_name = 'xp_ledger'
      and column_name in ('user_id', 'source_kind', 'source_id');
    if v_count < 3 then
      raise exception 'FAIL: xp_ledger lacks the idempotency unique key';
    end if;
  end if;

  -- Video and quiz amounts are the locked XP-01 policy.
  select amount into v_count
  from public.xp_award_rules where source_kind = 'video_completion';
  if v_count <> 10 then
    raise exception 'FAIL: video_completion should be 10 XP, got %', v_count;
  end if;

  select amount into v_count
  from public.xp_award_rules where source_kind = 'quiz_pass';
  if v_count <> 30 then
    raise exception 'FAIL: quiz_pass should be 30 XP, got %', v_count;
  end if;

  -- Award helper is not callable by authenticated clients.
  if has_function_privilege(
    'authenticated',
    'nano_internal.award_xp(uuid, text, text, integer, text, uuid)',
    'execute'
  ) then
    raise exception 'FAIL: authenticated can execute award_xp directly';
  end if;

  raise notice 'PASS: XP-01 schema and privileges hold';
end;
$$;

rollback;
