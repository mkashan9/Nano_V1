-- COM-03 smoke: join / invite RPCs present.

select count(*) >= 6 as join_invite_rpcs
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'join_community',
    'leave_community',
    'list_join_requests',
    'respond_join_request',
    'create_community_invite',
    'redeem_community_invite'
  );
