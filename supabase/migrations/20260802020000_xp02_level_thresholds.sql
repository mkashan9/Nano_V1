-- XP-02: level thresholds and a server-owned progress projection.
--
-- XP-01 made the ledger the only place XP can come from. Levels were still a
-- client guess at 250 XP each. This migration moves the curve into
-- level_rules, recalculates progress inside award_xp, and extends
-- my_xp_balance so Home and Me draw what the server says.

-- ---------------------------------------------------------------------------
-- Threshold table
-- ---------------------------------------------------------------------------
create table if not exists public.level_rules (
  level integer primary key check (level >= 1),
  min_xp integer not null check (min_xp >= 0),
  constraint level_rules_min_xp_unique unique (min_xp)
);

comment on table public.level_rules is
  'XP-02 cumulative XP required to reach each level. Flat 250/step at seed; '
  'ADM-05 may reshape the curve without a client release.';

insert into public.level_rules (level, min_xp)
select g, (g - 1) * 250
from generate_series(1, 40) as g
on conflict (level) do nothing;

-- ---------------------------------------------------------------------------
-- Per-learner projection (ledger total + derived level)
-- ---------------------------------------------------------------------------
create table if not exists public.xp_progress (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  total_xp integer not null default 0 check (total_xp >= 0),
  level integer not null default 1 references public.level_rules (level),
  xp_into_level integer not null default 0 check (xp_into_level >= 0),
  xp_to_next integer not null default 250 check (xp_to_next >= 0),
  xp_per_level integer not null default 250 check (xp_per_level >= 1),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.xp_progress is
  'XP-02 cached level derived from the ledger. Refreshed inside award_xp so '
  'Home never recomputes the curve and ledger totals always reconcile.';

alter table public.level_rules enable row level security;
alter table public.xp_progress enable row level security;

drop policy if exists level_rules_select_authenticated on public.level_rules;
create policy level_rules_select_authenticated on public.level_rules
  for select to authenticated
  using (true);

drop policy if exists xp_progress_select_own on public.xp_progress;
create policy xp_progress_select_own on public.xp_progress
  for select to authenticated
  using (user_id = auth.uid());

revoke all on table public.level_rules from public, anon, authenticated;
revoke all on table public.xp_progress from public, anon, authenticated;
grant select on table public.level_rules to authenticated, service_role;
grant select on table public.xp_progress to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Pure derivation helper
-- ---------------------------------------------------------------------------
create or replace function nano_internal.level_progress_for_xp(p_xp integer)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_xp integer := greatest(coalesce(p_xp, 0), 0);
  v_level integer;
  v_min integer;
  v_next_min integer;
  v_into integer;
  v_to_next integer;
  v_per integer;
begin
  select lr.level, lr.min_xp
    into v_level, v_min
  from public.level_rules lr
  where lr.min_xp <= v_xp
  order by lr.min_xp desc
  limit 1;

  if v_level is null then
    v_level := 1;
    v_min := 0;
  end if;

  select lr.min_xp into v_next_min
  from public.level_rules lr
  where lr.level = v_level + 1;

  v_into := v_xp - v_min;
  if v_next_min is null then
    v_to_next := 0;
    v_per := greatest(v_into, 1);
  else
    v_to_next := v_next_min - v_xp;
    v_per := v_next_min - v_min;
  end if;

  return jsonb_build_object(
    'level', v_level,
    'xp_into_level', v_into,
    'xp_to_next', v_to_next,
    'xp_per_level', v_per,
    'min_xp', v_min,
    'next_min_xp', v_next_min
  );
end;
$$;

revoke all on function nano_internal.level_progress_for_xp(integer)
  from public, anon, authenticated;
grant execute on function nano_internal.level_progress_for_xp(integer)
  to service_role;

create or replace function nano_internal.refresh_xp_progress(p_user_id uuid)
returns public.xp_progress
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_total integer;
  v_prog jsonb;
  v_row public.xp_progress;
begin
  if p_user_id is null then
    raise exception using errcode = 'NX001', message = 'A learner is required.';
  end if;

  select coalesce(sum(amount), 0) into v_total
  from public.xp_ledger
  where user_id = p_user_id;

  -- Reversals can drive the sum negative briefly in theory; level never does.
  v_total := greatest(v_total, 0);
  v_prog := nano_internal.level_progress_for_xp(v_total);

  insert into public.xp_progress as p
    (user_id, total_xp, level, xp_into_level, xp_to_next, xp_per_level, updated_at)
  values (
    p_user_id,
    v_total,
    (v_prog ->> 'level')::integer,
    (v_prog ->> 'xp_into_level')::integer,
    (v_prog ->> 'xp_to_next')::integer,
    (v_prog ->> 'xp_per_level')::integer,
    timezone('utc', now())
  )
  on conflict (user_id) do update
    set total_xp = excluded.total_xp,
        level = excluded.level,
        xp_into_level = excluded.xp_into_level,
        xp_to_next = excluded.xp_to_next,
        xp_per_level = excluded.xp_per_level,
        updated_at = excluded.updated_at
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function nano_internal.refresh_xp_progress(uuid)
  from public, anon, authenticated;
grant execute on function nano_internal.refresh_xp_progress(uuid)
  to service_role;

-- ---------------------------------------------------------------------------
-- award_xp: same body as XP-01, plus progress refresh after a new row
-- ---------------------------------------------------------------------------
create or replace function nano_internal.award_xp(
  p_user_id uuid,
  p_source_kind text,
  p_source_id text,
  p_amount integer default null,
  p_reason text default '',
  p_awarded_by uuid default null
)
returns public.xp_ledger
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_amount integer;
  v_rule_amount integer;
  v_cap integer;
  v_today integer;
  v_row public.xp_ledger;
begin
  if p_user_id is null or btrim(coalesce(p_source_id, '')) = '' then
    raise exception using
      errcode = 'NX001',
      message = 'An XP award needs a learner and a source.';
  end if;

  select amount into v_rule_amount
  from public.xp_award_rules
  where source_kind = p_source_kind;

  if v_rule_amount is null then
    raise exception using
      errcode = 'NX002',
      message = 'That XP source is not defined.';
  end if;

  if p_source_kind in ('manual_adjust', 'reversal') then
    v_amount := p_amount;
    if v_amount is null or v_amount = 0 then
      raise exception using
        errcode = 'NX003',
        message = 'A manual XP change needs a non-zero amount.';
    end if;
    if btrim(coalesce(p_reason, '')) = '' then
      raise exception using
        errcode = 'NX004',
        message = 'A manual XP change needs a reason.';
    end if;
  else
    v_amount := v_rule_amount;
  end if;

  select * into v_row
  from public.xp_ledger
  where user_id = p_user_id
    and source_kind = p_source_kind
    and source_id = btrim(p_source_id);

  if v_row.id is not null then
    return v_row;
  end if;

  if v_amount > 0 then
    select daily_cap into v_cap from public.xp_policy where id;
    select coalesce(sum(amount), 0) into v_today
    from public.xp_ledger
    where user_id = p_user_id
      and amount > 0
      and awarded_at >= date_trunc('day', timezone('utc', now()));

    if v_today >= v_cap then
      return null;
    end if;

    if v_today + v_amount > v_cap then
      v_amount := v_cap - v_today;
    end if;
  end if;

  insert into public.xp_ledger
    (user_id, amount, source_kind, source_id, reason, awarded_by)
  values (
    p_user_id,
    v_amount,
    p_source_kind,
    btrim(p_source_id),
    coalesce(p_reason, ''),
    p_awarded_by
  )
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    coalesce(p_awarded_by, p_user_id),
    case when p_awarded_by is not null then 'platform_admin' else 'student' end,
    'create',
    'xp_ledger',
    v_row.id::text,
    jsonb_build_object(
      'user_id', p_user_id,
      'amount', v_amount,
      'source_kind', p_source_kind,
      'source_id', btrim(p_source_id),
      'reason', coalesce(p_reason, '')
    )
  );

  -- XP-02: keep the projection in lockstep with the ledger.
  perform nano_internal.refresh_xp_progress(p_user_id);

  return v_row;
end;
$$;

revoke all on function nano_internal.award_xp(uuid, text, text, integer, text, uuid)
  from public, anon, authenticated;
grant execute on function nano_internal.award_xp(uuid, text, text, integer, text, uuid)
  to service_role;

-- ---------------------------------------------------------------------------
-- Learner balance now carries authoritative level fields
-- ---------------------------------------------------------------------------
create or replace function public.my_xp_balance()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_uid uuid := auth.uid();
  v_total integer;
  v_today integer;
  v_cap integer;
  v_prog public.xp_progress;
  v_derived jsonb;
begin
  if v_uid is null then
    raise exception using errcode = 'NX010', message = 'Authentication required.';
  end if;

  select coalesce(sum(amount), 0) into v_total
  from public.xp_ledger
  where user_id = v_uid;

  v_total := greatest(v_total, 0);

  select coalesce(sum(amount), 0) into v_today
  from public.xp_ledger
  where user_id = v_uid
    and amount > 0
    and awarded_at >= date_trunc('day', timezone('utc', now()));

  select daily_cap into v_cap from public.xp_policy where id;

  select * into v_prog from public.xp_progress where user_id = v_uid;
  if v_prog.user_id is null or v_prog.total_xp is distinct from v_total then
    v_prog := nano_internal.refresh_xp_progress(v_uid);
  end if;

  v_derived := nano_internal.level_progress_for_xp(v_total);

  return jsonb_build_object(
    'total', v_total,
    'today', v_today,
    'daily_cap', v_cap,
    'remaining_today', greatest(v_cap - v_today, 0),
    'level', v_prog.level,
    'xp_into_level', v_prog.xp_into_level,
    'xp_to_next', v_prog.xp_to_next,
    'xp_per_level', v_prog.xp_per_level,
    'reconciled',
      v_prog.level = (v_derived ->> 'level')::integer
      and v_prog.total_xp = v_total
  );
end;
$$;

revoke all on function public.my_xp_balance() from public, anon;
grant execute on function public.my_xp_balance() to authenticated, service_role;

-- Backfill progress for anyone who already has ledger rows.
do $$
declare
  r record;
begin
  for r in
    select distinct user_id from public.xp_ledger
  loop
    perform nano_internal.refresh_xp_progress(r.user_id);
  end loop;
end;
$$;
