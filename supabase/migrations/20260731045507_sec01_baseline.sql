-- SEC-01: Supabase baseline (remote-first, no Docker)
-- Extensions pgcrypto + uuid-ossp are expected on Supabase; CREATE IF NOT EXISTS is safe.

create extension if not exists "pgcrypto" with schema extensions;
create extension if not exists "uuid-ossp" with schema extensions;

-- Shared updated_at trigger helper for future tables.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

comment on function public.set_updated_at() is
  'Sets NEW.updated_at to UTC now(); attach via BEFORE UPDATE triggers.';

-- Read-only health row so clients can verify connectivity without service role.
create table if not exists public.app_health (
  id text primary key default 'default',
  environment text not null default 'development',
  schema_version text not null,
  notes text not null default '',
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.app_health is
  'Disposable connectivity / schema version probe. Not for product data.';

alter table public.app_health enable row level security;

drop policy if exists app_health_select_authenticated on public.app_health;
drop policy if exists app_health_select_anon on public.app_health;

create policy app_health_select_anon
  on public.app_health
  for select
  to anon
  using (true);

create policy app_health_select_authenticated
  on public.app_health
  for select
  to authenticated
  using (true);

-- No insert/update/delete policies for anon/authenticated (service role only).

insert into public.app_health (id, environment, schema_version, notes)
values (
  'default',
  'development',
  'SEC-01',
  'Baseline applied for Nano remote-first workflow'
)
on conflict (id) do update
set
  environment = excluded.environment,
  schema_version = excluded.schema_version,
  notes = excluded.notes,
  updated_at = timezone('utc', now());
