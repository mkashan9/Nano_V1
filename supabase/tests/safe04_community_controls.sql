-- SAFE-04 smoke: tables + entitlement / policy RPCs.

select to_regclass('public.platform_community_policy') is not null as platform_policy;
select to_regclass('public.school_community_policies') is not null as school_policies;

select count(*) >= 5 as public_rpcs
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'my_community_entitlements',
    'get_platform_community_policy',
    'upsert_platform_community_policy',
    'get_school_community_policy',
    'upsert_school_community_policy',
    'list_school_community_policies'
  );

select count(*) >= 2 as internal_helpers
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'nano_internal'
  and p.proname in (
    'current_user_communities_allowed',
    'assert_communities_allowed',
    'current_user_is_senior_learner'
  );

select communities_enabled = false as platform_default_off
from public.platform_community_policy
where id = 1;
