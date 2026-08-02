-- GME-01: learner game catalog + eligibility (reuse ADM-06 games / game_versions).
-- Play host / sessions / score verify stay GME-02+.

alter table public.game_versions
  add column if not exists independent_allowed boolean not null default true;

comment on column public.game_versions.independent_allowed is
  'GME-01: when false, independent students cannot see this published version.';

-- Number Rush: junior practice, open to school + independent.
update public.game_versions
set independent_allowed = true
where id = '61000000-0000-0000-0000-000000000001';

-- School Circuit: published school-only senior practice (eligibility probe).
insert into public.games (id, slug, category, sort_order) values
  ('60000000-0000-0000-0000-000000000003', 'school_circuit', 'challenge', 15)
on conflict (id) do nothing;

insert into public.game_versions
  (id, game_id, version, title_en, title_ur, summary_en, summary_ur,
   min_grade, max_grade, status, enabled, entry_kind, entry_ref,
   independent_allowed, published_at)
values
  (
    '61000000-0000-0000-0000-000000000003',
    '60000000-0000-0000-0000-000000000003',
    1,
    'School Circuit', 'اسکول سرکٹ',
    'A school-linked challenge for grades 6–12.',
    'جماعت 6 تا 12 کے لیے اسکول سے منسلک چیلنج۔',
    6, 12, 'published', true, 'web', 'fixture://school_circuit',
    false, timezone('utc', now())
  )
on conflict (id) do nothing;

create or replace function nano_internal.game_version_is_eligible(p_version_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
  select exists (
    select 1
    from public.game_versions gv
    join public.profiles p on p.id = auth.uid()
    where gv.id = p_version_id
      and gv.status = 'published'
      and gv.enabled
      and (
        gv.min_grade is null
        or coalesce(nano_internal.learner_grade(), gv.min_grade) >= gv.min_grade
      )
      and (
        gv.max_grade is null
        or coalesce(nano_internal.learner_grade(), gv.max_grade) <= gv.max_grade
      )
      and (
        gv.independent_allowed
        or p.account_kind <> 'independent_student'::public.account_kind
      )
      and p.account_kind in (
        'school_student'::public.account_kind,
        'independent_student'::public.account_kind
      )
  );
$$;

revoke all on function nano_internal.game_version_is_eligible(uuid) from public, anon;
grant execute on function nano_internal.game_version_is_eligible(uuid)
  to authenticated, service_role;

create or replace function public.list_games_for_learner()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_uid uuid := auth.uid();
  v_items jsonb;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = v_uid
      and p.account_kind in (
        'school_student'::public.account_kind,
        'independent_student'::public.account_kind
      )
  ) then
    raise exception using
      errcode = 'NS142',
      message = 'Games catalog is for students only.';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'game_id', g.id,
    'version_id', gv.id,
    'slug', g.slug,
    'category', g.category,
    'sort_order', g.sort_order,
    'version', gv.version,
    'title_en', gv.title_en,
    'title_ur', gv.title_ur,
    'summary_en', gv.summary_en,
    'summary_ur', gv.summary_ur,
    'min_grade', gv.min_grade,
    'max_grade', gv.max_grade,
    'entry_kind', gv.entry_kind,
    'entry_ref', gv.entry_ref,
    'independent_allowed', gv.independent_allowed
  ) order by g.sort_order, gv.title_en), '[]'::jsonb)
  into v_items
  from public.game_versions gv
  join public.games g on g.id = gv.game_id
  where nano_internal.game_version_is_eligible(gv.id);

  return jsonb_build_object(
    'games', v_items,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

revoke all on function public.list_games_for_learner() from public, anon;
grant execute on function public.list_games_for_learner()
  to authenticated, service_role;

comment on function public.list_games_for_learner() is
  'GME-01 learner catalog: published+enabled+grade+independent gate.';
comment on function nano_internal.game_version_is_eligible(uuid) is
  'GME-01 server eligibility for one game version.';
