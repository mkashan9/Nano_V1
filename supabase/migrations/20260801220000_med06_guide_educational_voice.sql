-- MED-06: cast the Learning Guide.
--
-- The owner listened to five Fish candidates on the authored greeting and
-- quiz lines and chose Educational Guide
-- (reference_id = 2c408095b1294de896376eff6a638d90). ADR-0008 records why the
-- guide is a female teacher rather than the mascot speaking: warm, clear,
-- measured, background rather than foreground.
--
-- A new row rather than an edit of guide_fish_stock, because the voice id is
-- part of the reuse hash (MED-03). Editing in place would silently keep every
-- recording made in the stock voice under a name that no longer matches.
-- Stock stays enabled but not default, so a deliberate request for it still
-- works and the history of why it existed is not rewritten.

insert into public.narration_voices
  (id, provider_id, provider_voice_name, display_name, style, locales,
   is_default, is_enabled, notes)
values (
  'guide_educational',
  'fish_audio_voice',
  '2c408095b1294de896376eff6a638d90',
  'Nano Learning Guide',
  'warm, clear, measured, teacherly',
  array['en', 'ur'],
  false,
  true,
  'MED-06 / ADR-0008: Fish Educational Guide. Female teacher register for a '
  || 'background guiding voice; not the mascot speaking. Chosen by the owner '
  || 'from five candidates on 2026-08-01 against the authored greeting and '
  || 'quiz lines.'
)
on conflict (id) do update set
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
set is_default = true, updated_at = timezone('utc', now())
where id = 'guide_educational';

update public.narration_voices
set
  notes = notes
    || ' Superseded as default by guide_educational (ADR-0008) on 2026-08-01.',
  updated_at = timezone('utc', now())
where id = 'guide_fish_stock'
  and notes not like '%Superseded as default by guide_educational%';
