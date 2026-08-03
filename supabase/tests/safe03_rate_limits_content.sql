-- SAFE-03 smoke: tables + helpers + public check RPCs.

select to_regclass('public.safety_rate_limits') is not null as rate_limits;
select to_regclass('public.restricted_terms') is not null as restricted_terms;
select to_regclass('public.link_allowlist_hosts') is not null as link_hosts;

select count(*) >= 2 as policy_rpcs
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('check_safety_text', 'my_safety_rate_status');

select count(*) >= 3 as internal_helpers
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'nano_internal'
  and p.proname in (
    'assert_rate_limit',
    'assert_text_allowed',
    'assert_community_message_allowed'
  );
