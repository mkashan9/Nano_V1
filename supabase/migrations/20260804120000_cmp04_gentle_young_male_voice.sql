-- CMP-04: humanoid companion default voice (gentle young male, Fish Audio).
--
-- VOICE_APPROXIMATION_USED: Gemini adapter may fall back to Puck when no
-- provider voice is resolved; Fish reference_id PENDING_OWNER_REFERENCE until
-- the owner supplies a clone. Historical rows (aoede, guide_fish_stock,
-- guide_educational) are not deleted.

insert into public.narration_voices
  (id, provider_id, provider_voice_name, display_name, style, locales,
   is_default, is_enabled, notes)
values (
  'gentle_young_male_c48e8683',
  'fish_audio_voice',
  'PENDING_OWNER_REFERENCE',
  'Nano Learning Guide',
  'gentle, young, male',
  array['en', 'ur'],
  false,
  true,
  'CMP-04: default companion narration voice. Replace provider_voice_name with '
  'Fish reference_id when owner approves; new row if voice id changes.'
)
on conflict (id) do update
set
  provider_id = excluded.provider_id,
  provider_voice_name = excluded.provider_voice_name,
  display_name = excluded.display_name,
  style = excluded.style,
  locales = excluded.locales,
  is_enabled = excluded.is_enabled,
  notes = excluded.notes,
  updated_at = timezone('utc', now());

update public.narration_voices
set is_default = false, updated_at = timezone('utc', now())
where is_default;

update public.narration_voices
set
  is_default = true,
  updated_at = timezone('utc', now())
where id = 'gentle_young_male_c48e8683';

update public.narration_voices
set
  is_enabled = false,
  notes = notes || ' Superseded by CMP-04 gentle_young_male_c48e8683; kept for provenance.',
  updated_at = timezone('utc', now())
where id = 'aoede';

update public.narration_voices
set
  is_default = false,
  notes = coalesce(notes, '') || ' Superseded as default by CMP-04 gentle_young_male_c48e8683.',
  updated_at = timezone('utc', now())
where id in ('guide_fish_stock', 'guide_educational');
