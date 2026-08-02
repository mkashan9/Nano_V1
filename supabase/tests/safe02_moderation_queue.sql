-- SAFE-02 smoke: moderation RPCs exist.

select to_regclass('public.moderation_evidence_access') is not null
  as evidence_access_table;

select count(*) >= 3 as moderation_rpcs
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'list_user_reports_for_moderation',
    'claim_user_report',
    'resolve_user_report'
  );
