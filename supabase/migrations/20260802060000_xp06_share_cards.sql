-- XP-06: featured achievements + privacy-safe share cards.
--
-- Pins are max 3 and must reference awards the learner already owns.
-- build_share_card returns first-name-only payloads with no school records.
-- Image delivery and social targets remain SOC-04.

create table if not exists public.featured_achievements (
  user_id uuid not null references public.profiles (id) on delete cascade,
  award_id uuid not null
    references public.achievement_awards (id) on delete cascade,
  sort_order integer not null check (sort_order between 1 and 3),
  created_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, award_id),
  unique (user_id, sort_order)
);

comment on table public.featured_achievements is
  'XP-06 Me pins (max 3). Own awards only; set via set_featured_achievements.';

create index if not exists featured_achievements_user_sort_idx
  on public.featured_achievements (user_id, sort_order);

alter table public.featured_achievements enable row level security;

drop policy if exists featured_achievements_select_own
  on public.featured_achievements;
create policy featured_achievements_select_own on public.featured_achievements
  for select to authenticated
  using (user_id = auth.uid());

revoke all on table public.featured_achievements
  from public, anon, authenticated;
grant select on table public.featured_achievements
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Featured read / replace
-- ---------------------------------------------------------------------------
create or replace function public.my_featured_achievements()
returns table (
  award_id uuid,
  sort_order integer,
  slug text,
  kind text,
  title_en text,
  title_ur text,
  description_en text,
  description_ur text,
  awarded_at timestamptz
)
language sql
security definer
set search_path = pg_catalog, public
as $$
  select
    a.id as award_id,
    f.sort_order,
    d.slug,
    d.kind,
    d.title_en,
    d.title_ur,
    d.description_en,
    d.description_ur,
    a.awarded_at
  from public.featured_achievements f
  join public.achievement_awards a on a.id = f.award_id
  join public.achievement_definitions d on d.id = a.achievement_id
  where f.user_id = auth.uid()
  order by f.sort_order;
$$;

revoke all on function public.my_featured_achievements() from public, anon;
grant execute on function public.my_featured_achievements()
  to authenticated, service_role;

create or replace function public.set_featured_achievements(p_award_ids uuid[])
returns table (
  award_id uuid,
  sort_order integer,
  slug text,
  kind text,
  title_en text,
  title_ur text,
  description_en text,
  description_ur text,
  awarded_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_uid uuid := auth.uid();
  v_id uuid;
  v_ord integer := 0;
  v_seen uuid[] := '{}'::uuid[];
begin
  if v_uid is null then
    raise exception using
      errcode = 'NX060',
      message = 'Sign in to feature achievements.';
  end if;

  delete from public.featured_achievements where user_id = v_uid;

  if p_award_ids is null then
    return query select * from public.my_featured_achievements();
    return;
  end if;

  foreach v_id in array p_award_ids
  loop
    if v_id is null then
      continue;
    end if;
    if v_id = any (v_seen) then
      continue;
    end if;
    if not exists (
      select 1
      from public.achievement_awards a
      where a.id = v_id and a.user_id = v_uid
    ) then
      raise exception using
        errcode = 'NX061',
        message = 'You can only feature achievements you already earned.';
    end if;

    v_ord := v_ord + 1;
    if v_ord > 3 then
      exit;
    end if;

    insert into public.featured_achievements (user_id, award_id, sort_order)
    values (v_uid, v_id, v_ord);
    v_seen := array_append(v_seen, v_id);
  end loop;

  return query select * from public.my_featured_achievements();
end;
$$;

revoke all on function public.set_featured_achievements(uuid[])
  from public, anon;
grant execute on function public.set_featured_achievements(uuid[])
  to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Privacy-safe share card builder
-- ---------------------------------------------------------------------------
create or replace function public.build_share_card(
  p_kind text,
  p_award_id uuid default null,
  p_score_percent integer default null,
  p_passed boolean default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_uid uuid := auth.uid();
  v_name text;
  v_first text;
  v_def public.achievement_definitions;
  v_award public.achievement_awards;
  v_score integer;
  v_passed boolean;
  v_headline_en text;
  v_headline_ur text;
  v_body_en text;
  v_body_ur text;
begin
  if v_uid is null then
    raise exception using
      errcode = 'NX062',
      message = 'Sign in to build a share card.';
  end if;

  select coalesce(nullif(btrim(display_name), ''), 'Learner')
  into v_name
  from public.profiles
  where id = v_uid;

  v_first := split_part(v_name, ' ', 1);
  if v_first = '' then
    v_first := 'Learner';
  end if;

  if p_kind = 'achievement' then
    if p_award_id is null then
      raise exception using
        errcode = 'NX063',
        message = 'An achievement share needs an award id.';
    end if;

    select * into v_award
    from public.achievement_awards
    where id = p_award_id and user_id = v_uid;

    if v_award.id is null then
      raise exception using
        errcode = 'NX064',
        message = 'You can only share achievements you earned.';
    end if;

    select * into v_def
    from public.achievement_definitions
    where id = v_award.achievement_id;

    v_headline_en := v_first || ' earned ' || v_def.title_en;
    v_headline_ur := v_first || ' نے ' || v_def.title_ur || ' حاصل کیا';
    v_body_en := nullif(btrim(v_def.description_en), '');
    v_body_ur := nullif(btrim(v_def.description_ur), '');
    if v_body_en is null then
      v_body_en := 'A Nano achievement unlocked.';
    end if;
    if v_body_ur is null then
      v_body_ur := 'Nano کا ایک اعزاز کھلا۔';
    end if;

    return jsonb_build_object(
      'kind', 'achievement',
      'first_name', v_first,
      'headline_en', v_headline_en,
      'headline_ur', v_headline_ur,
      'body_en', v_body_en,
      'body_ur', v_body_ur,
      'share_text_en', v_headline_en || ' on Nano! ' || v_body_en,
      'share_text_ur', v_headline_ur || ' — Nano! ' || v_body_ur,
      'slug', v_def.slug
    );
  end if;

  if p_kind = 'quiz_score' then
    v_score := greatest(0, least(100, coalesce(p_score_percent, 0)));
    v_passed := coalesce(p_passed, false);
    if v_passed then
      v_headline_en :=
        v_first || ' scored ' || v_score::text || '% on a Nano quiz';
      v_headline_ur :=
        v_first || ' نے Nano کوئز میں ' || v_score::text || '% حاصل کیے';
    else
      v_headline_en :=
        v_first || ' tried a Nano quiz (' || v_score::text || '%)';
      v_headline_ur :=
        v_first || ' نے Nano کوئز کیا (' || v_score::text || '%)';
    end if;
    v_body_en := 'Practice makes progress — no academic marks here.';
    v_body_ur := 'مشق سے پیشرفت — یہاں تعلیمی نمبر نہیں۔';

    return jsonb_build_object(
      'kind', 'quiz_score',
      'first_name', v_first,
      'headline_en', v_headline_en,
      'headline_ur', v_headline_ur,
      'body_en', v_body_en,
      'body_ur', v_body_ur,
      'share_text_en', v_headline_en || '! ' || v_body_en,
      'share_text_ur', v_headline_ur || '! ' || v_body_ur,
      'score_percent', v_score
    );
  end if;

  raise exception using
    errcode = 'NX065',
    message = 'Unknown share card kind.';
end;
$$;

revoke all on function public.build_share_card(text, uuid, integer, boolean)
  from public, anon;
grant execute on function public.build_share_card(text, uuid, integer, boolean)
  to authenticated, service_role;
