# Migration conventions (SEC-01)

## Naming

```
supabase/migrations/YYYYMMDDHHMMSS_snake_case_name.sql
```

- One concern per migration.
- Forward-only in shared remotes; document compensating SQL in module KNOWN_ISSUES / DECISIONS when needed.
- Prefer `create … if not exists` / idempotent policies for baselines.

## Remote-first apply (no Docker)

1. Author the SQL file in git.
2. Apply to **development** (`nano_v1` / `jjsnvmxasbtimesjsyoy`) via Supabase MCP `apply_migration` **or** CLI after `supabase link` (owner-approved).
3. Align the local filename timestamp with the remote migration version when MCP assigns one.
4. Verify with `list_tables` / `execute_sql` / `list_migrations`.
5. Never apply unreviewed SQL to staging/production.

## Forbidden without owner approval

- `supabase db push` to non-dev
- Destructive resets on shared remotes
- Service-role keys in apps or committed files

## RLS rule of thumb

Every new table exposed to PostgREST must enable RLS in the same migration that creates it (even if policies are expanded in SEC-02).
