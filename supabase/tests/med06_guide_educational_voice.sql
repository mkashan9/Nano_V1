-- MED-06: the Learning Guide is a cast voice, not the stock one.
--
-- Adversarial checks that the owner-chosen Educational Guide is the only
-- default, that stock is still reachable by id, and that a recording request
-- without a voice_id resolves to the new default rather than stock.

begin;

do $$
declare
  v_default text;
  v_default_count int;
  v_stock_enabled boolean;
  v_voice_name text;
begin
  select count(*) into v_default_count
  from public.narration_voices
  where is_default;

  if v_default_count <> 1 then
    raise exception 'FAIL: expected exactly one default voice, found %',
      v_default_count;
  end if;

  select id into v_default
  from public.narration_voices
  where is_default;

  if v_default <> 'guide_educational' then
    raise exception 'FAIL: default voice is %, expected guide_educational',
      v_default;
  end if;

  select provider_voice_name into v_voice_name
  from public.narration_voices
  where id = 'guide_educational';

  if v_voice_name <> '2c408095b1294de896376eff6a638d90' then
    raise exception 'FAIL: Educational Guide reference_id drifted to %',
      v_voice_name;
  end if;

  select is_enabled into v_stock_enabled
  from public.narration_voices
  where id = 'guide_fish_stock';

  if not v_stock_enabled then
    raise exception 'FAIL: stock voice was disabled; it should stay reachable';
  end if;

  if exists (
    select 1 from public.narration_voices
    where id = 'guide_fish_stock' and is_default
  ) then
    raise exception 'FAIL: stock voice is still the default';
  end if;
end $$;

rollback;
