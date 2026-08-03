-- COM-01 smoke: discovery tables + RPCs.

select to_regclass('public.communities') is not null as communities_table;
select to_regclass('public.community_memberships') is not null as memberships_table;

select count(*) >= 3 as public_rpcs
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'my_communities',
    'discover_public_communities',
    'get_community_detail'
  );

select count(*) >= 3 as seeded_public
from public.communities
where visibility = 'public' and status = 'active';
