-- SEC-02 adversarial checks (run via MCP execute_sql as a single batch).
-- Impersonate Ali (Alpha student): must see ALPHA01 only.

select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;
select code from public.schools order by code;
-- Expect: ALPHA01 only (no BETA02)
