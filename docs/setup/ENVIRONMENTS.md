# Nano Environments (remote-first, no Docker)

## Environments

| Name | Purpose | Supabase |
|------|---------|----------|
| development | Daily integration, disposable data | Remote project `nano_v1` (`jjsnvmxasbtimesjsyoy`) |
| staging | Release candidates (future) | Separate project TBD |
| production | Live users (future) | Separate project TBD |

## No Docker

Owner policy: **do not use Docker** and do not run `supabase start`.

Alternatives:

1. Author SQL migrations in `supabase/migrations/`.
2. Apply to the remote **development** project via Supabase MCP `apply_migration` or CLI after `supabase link` (owner-approved).
3. Run SQL / RLS checks with MCP `execute_sql` against development.
4. Deploy Edge Functions only to development with owner approval (`supabase functions deploy` is still gated).
5. Keep secrets in `supabase/functions/.env.local` (gitignored) and remote function secrets.

## Flutter compile-time values

```bash
flutter run \
  --dart-define=NANO_ENV=development \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Never place service-role keys in Flutter.
