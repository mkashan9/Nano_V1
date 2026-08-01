-- MED-06 Fish Audio narration and composed reaction clips: the provider registry.
--
-- MED-03 and MED-04 were written against Gemini. Neither ever ran: no key was
-- ever set, so every voice and every clip failed closed and every companion
-- surface kept its local art. The owner has since chosen different providers, so
-- this migration changes which provider is default rather than repairing
-- anything that was in use.
--
-- The Gemini rows stay. They are disabled, not deleted, because `generated_assets`
-- and `narration_voices` reference provider ids, and because a provider that
-- turns out to be wrong should be a row that can be switched back rather than a
-- migration that has to be written again.
--
-- No key appears here. Both providers read their key from an Edge Function
-- secret at call time, and a missing key is an ordinary recorded failure.

-- ---------------------------------------------------------------------------
-- A provider that composes is not a provider that invents
-- ---------------------------------------------------------------------------
-- Veo was asked for a clip and answered with footage it had imagined. json2video
-- is a compositor: it is handed a picture and returns that picture moving. The
-- difference matters to the database, not just to the adapter, because a
-- compositor cannot be asked for a reaction whose picture nobody approved. This
-- column is what lets `request_reaction_clip` know which kind of provider it is
-- about to spend money on.
alter table public.generation_providers
  add column if not exists composes_from_art boolean not null default false;

comment on column public.generation_providers.composes_from_art is
  'MED-06 true when this provider animates a picture it is given rather than '
  'generating footage from a description. A composing provider may only be sent '
  'art a reviewer has already approved.';

insert into public.generation_providers
  (id, kind, is_enabled, is_default, requires_key, composes_from_art, notes)
values
  (
    'fish_audio_voice',
    'voice',
    true,
    false,
    true,
    false,
    'Learning Guide narration through Fish Audio /v1/tts. Returns MP3. '
    'VOICE_PROVIDER_API_KEY in Edge Function secrets; never in git or a client.'
  ),
  (
    'json2video_compose',
    'video',
    true,
    false,
    true,
    true,
    'Reaction clips composed from approved companion art through json2video '
    '/v2/movies. Asynchronous: submit returns a project, frames arrive later. '
    'VIDEO_PROVIDER_API_KEY in Edge Function secrets; never in git or a client.'
  )
on conflict (id) do update
set
  is_enabled = excluded.is_enabled,
  requires_key = excluded.requires_key,
  composes_from_art = excluded.composes_from_art,
  notes = excluded.notes,
  updated_at = timezone('utc', now());

-- One default per kind is a unique index, so the old default is cleared before
-- the new one is set. Doing both in one statement trips the index mid-update
-- (learned in MED-03).
update public.generation_providers
set is_default = false, updated_at = timezone('utc', now())
where kind in ('voice', 'video') and is_default;

update public.generation_providers
set is_default = true, updated_at = timezone('utc', now())
where id in ('fish_audio_voice', 'json2video_compose');

-- The Gemini adapters are still deployed and still work if a project points a
-- request at them by id. They are simply no longer what an unqualified ask gets.
update public.generation_providers
set
  is_enabled = false,
  notes = notes || ' Superseded by MED-06; kept for provenance and rollback.',
  updated_at = timezone('utc', now())
where id in ('gemini_voice_aoede', 'gemini_veo_video', 'configured_voice', 'configured_video');

-- ---------------------------------------------------------------------------
-- The Learning Guide's voice is now a Fish voice
-- ---------------------------------------------------------------------------
-- Aoede was Gemini's name for a voice Gemini owned. Fish identifies a voice by a
-- `reference_id` from its library, and the owner has not picked one yet, so this
-- row names the stock voice explicitly rather than leaving the column empty.
-- `stock` is the adapter's agreed word for "send no reference_id and let the
-- model use its own default voice" — a sentinel, because the column refuses an
-- empty string and because a blank would read as an oversight rather than a
-- decision.
--
-- This is a new row, not an edit of `aoede`. The voice id is part of the reuse
-- hash (MED-03), so a new id is what stops a recording made in one voice from
-- being handed back for a request that asked for another.
insert into public.narration_voices
  (id, provider_id, provider_voice_name, display_name, style, locales,
   is_default, is_enabled, notes)
values (
  'guide_fish_stock',
  'fish_audio_voice',
  'stock',
  'Nano Learning Guide',
  'breezy, warm, unhurried',
  array['en', 'ur'],
  false,
  true,
  'MED-06: Fish Audio stock voice. Replace provider_voice_name with a Fish '
  'reference_id once the owner picks one; that is a new row, not an edit, '
  'because the voice id is part of the reuse hash.'
)
on conflict (id) do nothing;

update public.narration_voices
set is_default = false, updated_at = timezone('utc', now())
where is_default;

update public.narration_voices
set is_default = true, updated_at = timezone('utc', now())
where id = 'guide_fish_stock';

update public.narration_voices
set
  is_enabled = false,
  notes = notes || ' Superseded by MED-06 (Gemini is no longer the voice provider).',
  updated_at = timezone('utc', now())
where id = 'aoede';
