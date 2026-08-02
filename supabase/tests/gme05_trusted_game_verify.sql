-- GME-05 presence: results tables + verifying completion RPC.

do $$
begin
  if to_regclass('public.game_results') is null then
    raise exception 'game_results missing';
  end if;
  if to_regclass('public.rejected_scores') is null then
    raise exception 'rejected_scores missing';
  end if;
  if to_regclass('public.game_score_submissions') is null then
    raise exception 'game_score_submissions missing';
  end if;
end $$;
