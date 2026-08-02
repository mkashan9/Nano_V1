-- GME-03 presence: flutter start allowed + Shape Sort published.

do $$
declare
  v_status text;
  v_kind text;
begin
  select status, entry_kind into v_status, v_kind
  from public.game_versions
  where id = '61000000-0000-0000-0000-000000000002';

  if v_kind is distinct from 'flutter' then
    raise exception 'shape_sort entry_kind missing';
  end if;
  if v_status is distinct from 'published' then
    raise exception 'shape_sort not published';
  end if;
end $$;
