# ADR-0002: Remote-first Supabase (no Docker)

## Status

Accepted (owner directive 2026-07-31)

## Context

Owner will not use Docker. Local `supabase start` is unavailable by policy.

## Decision

Use **remote-first** Supabase development:

1. Author migrations in `supabase/migrations/` in git.
2. Apply and verify against a remote **development** project (`nano_v1` until further environments exist).
3. Prefer Supabase MCP / CLI remote operations over local containers.
4. Edge Function secrets stay in ignored `.env.local` and remote function secrets (owner-approved).
5. RLS / SQL tests run against the remote development database (or CI job with hosted Postgres), never requiring Docker Desktop.
6. Do not document or require `supabase start` as a developer prerequisite.

## Consequences

- Faster setup on Windows without Docker.
- Shared dev data must remain disposable; never treat unclear remotes as playgrounds without classification.
- Production remains protected: no `db push` / deploy without owner approval and environment confirmation.
