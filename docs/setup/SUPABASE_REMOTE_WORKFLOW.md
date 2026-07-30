# Supabase remote workflow (no Docker)

## Link (once)

```bash
supabase link --project-ref jjsnvmxasbtimesjsyoy
```

## Migrations

1. Add files under `supabase/migrations/`.
2. Prefer MCP `apply_migration` for development.
3. Never apply unreviewed migrations to staging/production.

## Forbidden without owner approval

- `supabase db push` to non-dev
- `supabase functions deploy` to non-dev
- `supabase secrets set` for production
