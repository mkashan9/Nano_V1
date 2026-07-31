-- Manual / MCP verification queries for SEC-01 (run via execute_sql).
-- Expected: one row, schema_version SEC-01, RLS enabled.

select id, environment, schema_version from public.app_health where id = 'default';

select c.relname as table_name, c.relrowsecurity as rls_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname = 'app_health';
