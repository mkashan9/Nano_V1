-- SAFE-04 smoke: open Communities (no school gate).

select to_regclass('public.platform_community_policy') is not null as platform_policy;
select to_regclass('public.school_community_policies') is null as school_policies_removed;

select count(*) >= 3 as public_rpcs
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'my_community_entitlements',
    'get_platform_community_policy',
    'upsert_platform_community_policy'
  );

select count(*) = 0 as school_rpcs_gone
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'get_school_community_policy',
    'upsert_school_community_policy',
    'list_school_community_policies'
  );

select communities_enabled = true as platform_default_on
from public.platform_community_policy
where id = 1;
