-- SAFE-01 smoke: report RPCs exist; table is RPC-only.

select to_regclass('public.user_reports') is not null as user_reports_table;

select count(*) >= 3 as report_rpcs
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'submit_user_report',
    'submit_user_report_for_peer',
    'my_user_reports'
  );
