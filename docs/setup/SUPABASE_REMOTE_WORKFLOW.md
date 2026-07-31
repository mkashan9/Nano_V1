# Supabase remote workflow (no Docker)

Owner policy (ADR-0002): **do not use Docker** and do not run `supabase start`.

## Development project

| Field | Value |
|-------|-------|
| Name | `nano_v1` |
| Ref | `jjsnvmxasbtimesjsyoy` |
| URL | `https://jjsnvmxasbtimesjsyoy.supabase.co` |
| Class | development (disposable) |

## Link CLI (optional)

```powershell
cd D:\nano
supabase link --project-ref jjsnvmxasbtimesjsyoy
```

## Migrations

1. Add files under `supabase/migrations/` following [MIGRATION_CONVENTIONS.md](MIGRATION_CONVENTIONS.md).
2. Prefer MCP `apply_migration` for development.
3. Keep git and remote migration history aligned.
4. Never apply unreviewed migrations to staging/production.

## Client dart-defines

```powershell
flutter run -d chrome `
  --dart-define=NANO_ENV=development `
  --dart-define=SUPABASE_URL=https://jjsnvmxasbtimesjsyoy.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<publishable-anon-key>
```

Obtain the anon key from the Supabase dashboard or MCP `get_publishable_keys`. Never put the service-role key in Flutter.

## SEC-01 health probe

Table `public.app_health` (RLS: select for `anon` + `authenticated`).

Student debug strip → **DB health** → Check `app_health`.

## Forbidden without owner approval

- `supabase db push` to non-dev
- `supabase functions deploy` to non-dev
- `supabase secrets set` for production
