-- COM-02 smoke: create + role RPCs.

select count(*) >= 3 as public_rpcs
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'create_community',
    'list_community_members',
    'set_community_member_role'
  );
