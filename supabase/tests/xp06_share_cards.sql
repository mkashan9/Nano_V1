-- XP-06: featured pins are own-only; share cards omit school records.

begin;

do $$
begin
  if not exists (
    select 1 from information_schema.tables
    where table_schema = 'public' and table_name = 'featured_achievements'
  ) then
    raise exception 'featured_achievements missing';
  end if;

  if has_table_privilege('authenticated', 'public.featured_achievements', 'insert')
     or has_table_privilege('authenticated', 'public.featured_achievements', 'update')
     or has_table_privilege('authenticated', 'public.featured_achievements', 'delete')
  then
    raise exception 'authenticated must not write featured_achievements directly';
  end if;

  if to_regprocedure('public.my_featured_achievements()') is null then
    raise exception 'my_featured_achievements missing';
  end if;

  if to_regprocedure('public.set_featured_achievements(uuid[])') is null then
    raise exception 'set_featured_achievements missing';
  end if;

  if to_regprocedure(
       'public.build_share_card(text, uuid, integer, boolean)'
     ) is null then
    raise exception 'build_share_card missing';
  end if;

  raise notice 'xp06_share_cards: ok';
end;
$$;

rollback;
