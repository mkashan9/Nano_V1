-- SEC-01 follow-up: lock search_path on set_updated_at (advisor WARN).

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
  'Sets NEW.updated_at to UTC now(); attach via BEFORE UPDATE triggers. search_path locked.';
