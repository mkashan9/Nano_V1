-- COM-04 smoke: messaging RPCs present.

select count(*) >= 3 as message_rpcs
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'list_community_messages',
    'send_community_message',
    'toggle_message_reaction'
  );
