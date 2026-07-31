-- SEC-03 adversarial checks (MCP execute_sql).

-- 1) Suspend Alpha: Ali must see zero schools, then restore.
-- update schools set status = 'suspended' where code = 'ALPHA01';
-- impersonate Ali -> select code from schools -> expect empty
-- update schools set status = 'active' where code = 'ALPHA01';

-- 2) Ali cannot insert audit_events (expect RLS 42501).
-- set jwt sub = Ali, role authenticated
-- insert into audit_events ... -> denied

-- 3) Ali can select own device_sessions; cannot select security_incidents.
