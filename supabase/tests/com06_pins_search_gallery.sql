-- COM-06 smoke: pins/search/gallery/prefs RPCs.

select count(*) >= 5 as com06_rpcs
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'pin_community_message',
    'list_community_pins',
    'search_community_messages',
    'list_community_gallery',
    'set_community_member_prefs',
    'set_community_posting_mode'
  );

select to_regclass('public.community_member_prefs') is not null as prefs_table;
