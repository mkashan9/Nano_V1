-- COM-05 smoke: media RPCs and table present.

select count(*) >= 1 as prepare_rpc
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'prepare_community_media_upload';

select to_regclass('public.community_message_attachments') is not null
  as attachments_table;

select exists (
  select 1 from storage.buckets where id = 'community-media'
) as community_media_bucket;
