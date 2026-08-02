-- SOC-04: share cards prefer social handle (username) over legal first name.

create or replace function public.build_share_card(
  p_kind text,
  p_award_id uuid default null,
  p_score_percent integer default null,
  p_passed boolean default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_uid uuid := auth.uid();
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

  -- Prefer claimed username / privacy label; never school records.
  v_first := nano_internal.league_privacy_label(v_uid);
  if v_first is null or btrim(v_first) = '' then
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

comment on function public.build_share_card(text, uuid, integer, boolean) is
  'SOC-04/XP-06 privacy-safe share payloads; social label prefers username.';
