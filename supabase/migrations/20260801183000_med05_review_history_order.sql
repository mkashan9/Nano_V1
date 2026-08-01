-- MED-05 follow-up: make the order of decisions knowable.
--
-- Approving and then rejecting in the same transaction gave both rows the same
-- created_at, because now() is the transaction clock. The history then came back
-- in an arbitrary order, which for an audit record is worse than useless: it can
-- say the reviewer approved something they actually pulled.

alter table public.asset_review_events
  add column if not exists seq bigint generated always as identity;

create unique index if not exists asset_review_events_seq_idx
  on public.asset_review_events (seq);

-- Cosmetic but honest: two decisions a second apart should not read as
-- simultaneous just because they shared a transaction.
alter table public.asset_review_events
  alter column created_at set default timezone('utc', clock_timestamp());

comment on column public.asset_review_events.seq is
  'MED-05 append order. Two decisions in one transaction share a transaction '
  'clock, so the timestamp alone cannot say which came second.';

create or replace function public.asset_review_history(p_asset_id uuid)
returns table (
  id uuid,
  previous_moderation public.generated_asset_moderation,
  decision public.generated_asset_moderation,
  note text,
  reviewer_name text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NM010',
      message = 'Only platform admins can see review history.';
  end if;

  return query
  select
    e.id,
    e.previous_moderation,
    e.decision,
    e.note,
    p.display_name,
    e.created_at
  from public.asset_review_events e
  left join public.profiles p on p.id = e.reviewer_id
  where e.asset_id = p_asset_id
  order by e.seq desc;
end;
$$;

revoke all on function public.asset_review_history(uuid) from public, anon;
grant execute on function public.asset_review_history(uuid)
  to authenticated, service_role;
