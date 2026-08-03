-- SAFE-04 fix: Communities are open (Discord-like), not school-gated.
-- Schools are unrelated. Seniors are free by default; juniors stay blocked.
-- Platform switch remains as an emergency kill switch (default ON).

drop function if exists public.list_school_community_policies();
drop function if exists public.upsert_school_community_policy(uuid, boolean);
drop function if exists public.get_school_community_policy(uuid);

drop table if exists public.school_community_policies;

update public.platform_community_policy
set communities_enabled = true,
    updated_at = timezone('utc', now())
where id = 1
  and communities_enabled = false;

comment on table public.platform_community_policy is
  'SAFE-04 singleton: emergency platform kill switch for open Communities (default on). Schools do not gate Communities.';

create or replace function nano_internal.current_user_communities_allowed()
returns boolean
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_kind public.account_kind;
  v_platform boolean;
begin
  if auth.uid() is null then
    return false;
  end if;

  -- Explicit senior track only (junior or undecided stay blocked).
  if not nano_internal.current_user_is_senior_learner() then
    return false;
  end if;

  select p.account_kind
    into v_kind
  from public.profiles p
  where p.id = auth.uid()
    and p.status = 'active'::public.membership_status;

  if not found then
    return false;
  end if;

  if v_kind not in (
    'school_student'::public.account_kind,
    'independent_student'::public.account_kind
  ) then
    return false;
  end if;

  select coalesce(pcp.communities_enabled, true)
    into v_platform
  from public.platform_community_policy pcp
  where pcp.id = 1;

  -- Open Communities: school enrollment is irrelevant.
  return coalesce(v_platform, true);
end;
$$;

create or replace function public.my_community_entitlements()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_kind public.account_kind;
  v_platform boolean := true;
  v_senior boolean := false;
  v_allowed boolean := false;
  v_reason text := 'ok';
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED' using errcode = 'P0001';
  end if;

  v_senior := nano_internal.current_user_is_senior_learner();

  select p.account_kind
    into v_kind
  from public.profiles p
  where p.id = auth.uid();

  select coalesce(pcp.communities_enabled, true)
    into v_platform
  from public.platform_community_policy pcp
  where pcp.id = 1;
  v_platform := coalesce(v_platform, true);

  v_allowed := nano_internal.current_user_communities_allowed();

  if not v_senior then
    v_reason := 'junior_blocked';
  elsif not v_platform then
    v_reason := 'platform_disabled';
  elsif v_kind not in (
    'school_student'::public.account_kind,
    'independent_student'::public.account_kind
  ) then
    v_reason := 'not_learner';
  end if;

  return jsonb_build_object(
    'communities_enabled', v_allowed,
    'platform_enabled', v_platform,
    'school_enabled', null,
    'junior_blocked', not v_senior,
    'reason', v_reason
  );
end;
$$;
