-- MED-03 adversarial checks: what the voice changes about reuse, what a curator
-- may author, what may never be recorded, and what a learner is allowed to hear.
--
-- Every block rolls back, so the seeded nine companion lines survive the run.

-- ---------------------------------------------------------------------------
-- The voice is part of identity; the aspect ratio is not
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

select 'two_voices_are_two_recordings' as check,
  nano_internal.generated_asset_hash(
    'voice', 'narration_x', 'en', '1:1', 'Take your time.', 'v1', 'aoede'
  ) <> nano_internal.generated_asset_hash(
    'voice', 'narration_x', 'en', '1:1', 'Take your time.', 'v1', 'someone_else'
  ) as ok;

-- A recording has no shape. Two callers passing different harmless defaults must
-- not pay twice for the same audio.
select 'aspect_ratio_does_not_split_audio' as check,
  nano_internal.generated_asset_hash(
    'voice', 'narration_x', 'en', '1:1', 'Take your time.', 'v1', 'aoede'
  ) = nano_internal.generated_asset_hash(
    'voice', 'narration_x', 'en', '16:9', 'Take your time.', 'v1', 'aoede'
  ) as ok;

-- Art is unaffected: shape still matters there, and the old six-argument form
-- still answers for every MED-01 and MED-02 caller.
select 'aspect_ratio_still_splits_art' as check,
  nano_internal.generated_asset_hash(
    'image', 'guide_idle_staticArt', 'en', '1:1', 'a companion', 'v1'
  ) <> nano_internal.generated_asset_hash(
    'image', 'guide_idle_staticArt', 'en', '16:9', 'a companion', 'v1'
  ) as ok;

-- Language is not a near-enough match for speech. English audio must never be
-- offered for an Urdu line.
select 'language_splits_audio' as check,
  nano_internal.generated_asset_hash(
    'voice', 'narration_x', 'en', '1:1', 'Take your time.', 'v1', 'aoede'
  ) <> nano_internal.generated_asset_hash(
    'voice', 'narration_x', 'ur', '1:1', 'Take your time.', 'v1', 'aoede'
  ) as ok;
rollback;

-- ---------------------------------------------------------------------------
-- A request records the published wording, once
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $$
declare
  v_first jsonb;
  v_again jsonb;
  v_urdu jsonb;
  v_used integer;
begin
  v_first := public.request_narration_line('greeting-2', 'en');

  if (v_first->>'reused')::boolean then
    raise exception 'FAIL: a first recording reported reuse';
  end if;
  if v_first->'asset'->>'slot' <> 'narration_greeting-2' then
    raise exception 'FAIL: wrong slot %', v_first->'asset'->>'slot';
  end if;
  -- The words come from the database, not from the caller.
  if v_first->'asset'->>'prompt' <> 'Good to see you again.' then
    raise exception 'FAIL: wrong wording %', v_first->'asset'->>'prompt';
  end if;
  if v_first->'asset'->>'prompt_version' <> 'v1' then
    raise exception 'FAIL: wrong version %', v_first->'asset'->>'prompt_version';
  end if;
  if v_first->'asset'->>'voice_id' <> 'aoede'
     or v_first->'asset'->>'provider_id' <> 'gemini_voice_aoede' then
    raise exception 'FAIL: wrong voice or provider %', v_first->'asset';
  end if;

  select requests_count into v_used
  from public.generation_usage
  where scope = 'platform' and scope_key = '' and kind = 'voice'
    and usage_date = (timezone('utc', now()))::date;
  if coalesce(v_used, 0) <> 1 then
    raise exception 'FAIL: a new recording was not counted (%)', v_used;
  end if;

  v_again := public.request_narration_line('greeting-2', 'en');
  if not (v_again->>'reused')::boolean then
    raise exception 'FAIL: the same line was recorded twice';
  end if;

  select requests_count into v_used
  from public.generation_usage
  where scope = 'platform' and scope_key = '' and kind = 'voice'
    and usage_date = (timezone('utc', now()))::date;
  if v_used <> 1 then
    raise exception 'FAIL: a reused recording consumed budget (%)', v_used;
  end if;

  -- Urdu is a separate recording of separate words, not a translation of a file.
  v_urdu := public.request_narration_line('greeting-2', 'ur');
  if (v_urdu->>'reused')::boolean then
    raise exception 'FAIL: Urdu reused the English recording';
  end if;
  if v_urdu->'asset'->>'prompt' = v_first->'asset'->>'prompt' then
    raise exception 'FAIL: Urdu request carried the English wording';
  end if;
end $$;
select 'narration_request_uses_published_wording' as check, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- A line naming the learner's companion is never recorded
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $$
begin
  begin
    perform public.request_narration_line('greeting-1', 'en');
    raise exception 'FAIL: a placeholder line was recorded';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM007' then
      raise exception 'FAIL: unexpected refusal % %', sqlstate, sqlerrm;
    end if;
  end;

  -- Urdu carries the same placeholder, so it is refused for the same reason.
  begin
    perform public.request_narration_line('greeting-1', 'ur');
    raise exception 'FAIL: a placeholder line was recorded in Urdu';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM007' then
      raise exception 'FAIL: unexpected Urdu refusal %', sqlstate;
    end if;
  end;

  -- A refusal is not a half-finished job: nothing was created and nothing spent.
  if exists (select 1 from public.generated_assets where kind = 'voice') then
    raise exception 'FAIL: a refused recording still created a row';
  end if;
  if exists (
    select 1 from public.generation_usage where kind = 'voice'
  ) then
    raise exception 'FAIL: a refused recording still charged a budget';
  end if;
end $$;
select 'placeholder_line_is_never_recorded' as check, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Unknown lines, unknown voices, and voices on the wrong kind
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $$
begin
  begin
    perform public.request_narration_line('no-such-line', 'en');
    raise exception 'FAIL: an unknown line was accepted';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM004' then
      raise exception 'FAIL: unexpected unknown-line error %', sqlstate;
    end if;
  end;

  begin
    perform public.request_narration_line('idle-1', 'en', 'not_a_voice');
    raise exception 'FAIL: an unknown voice was accepted';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM002' then
      raise exception 'FAIL: unexpected unknown-voice error %', sqlstate;
    end if;
  end;

  -- A voice on an image is a category error, and a silent one would let the hash
  -- treat two identical pictures as different.
  begin
    perform public.request_generated_asset(
      'image', 'guide_idle_staticArt', 'a companion', 'v1',
      'en', '1:1', null, 'companion', null, 'aoede'
    );
    raise exception 'FAIL: an image was given a voice';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM002' then
      raise exception 'FAIL: unexpected voice-on-image error %', sqlstate;
    end if;
  end;
end $$;
select 'unknown_line_and_voice_are_refused' as check, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- A disabled voice stops recording without stopping the app
-- ---------------------------------------------------------------------------
begin;
-- Voices are edited before the role switch: `authenticated` has no write grant,
-- which a later block asserts.
update public.narration_voices set is_enabled = false where id = 'aoede';

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $$
begin
  begin
    perform public.request_narration_line('idle-1', 'en');
    raise exception 'FAIL: a disabled voice still recorded';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM002' then
      raise exception 'FAIL: unexpected disabled-voice error %', sqlstate;
    end if;
  end;
end $$;

-- Turning the voice off does not take the words away: captions are unaffected.
select 'disabled_voice_keeps_the_words' as check,
  (select count(*) from public.list_narration_lines('en')) = 9 as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Authoring is a curator's job only
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

do $$
begin
  begin
    perform public.create_narration_line_draft('learner-line', 'Say this.');
    raise exception 'FAIL: a learner authored a line';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM001' then
      raise exception 'FAIL: unexpected authoring error %', sqlstate;
    end if;
  end;

  begin
    perform public.request_narration_line('idle-1', 'en');
    raise exception 'FAIL: a learner requested a recording';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM001' then
      raise exception 'FAIL: unexpected request error %', sqlstate;
    end if;
  end;
end $$;

-- The authoring tables themselves are invisible, drafts included.
select 'learner_sees_no_authoring_tables' as check,
  (select count(*) from public.narration_lines) = 0
  and (select count(*) from public.narration_line_versions) = 0
  and (select count(*) from public.narration_voices) = 0 as ok;

select 'nobody_signed_in_can_edit_lines' as check,
  not has_table_privilege('authenticated', 'public.narration_lines', 'update')
  and not has_table_privilege(
    'authenticated', 'public.narration_line_versions', 'insert'
  )
  and not has_table_privilege('authenticated', 'public.narration_voices', 'update')
    as ok;

-- What a learner *may* read: published wording, and no audio, because nothing is
-- approved. The absence of a recording is an ordinary answer, not an error.
select 'learner_reads_wording_without_audio' as check,
  (select count(*) from public.list_narration_lines('en')) = 9
  and (select count(*) from public.list_narration_lines('en')
       where storage_path is not null) = 0 as ok;

select 'learner_reads_urdu_wording' as check,
  (select line_text from public.list_narration_lines('ur')
   where slug = 'idle-1') = 'آرام سے کریں۔' as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Published wording cannot be edited under a recording
-- ---------------------------------------------------------------------------
begin;
do $$
begin
  begin
    update public.narration_line_versions
    set text = 'Something else entirely.'
    where status = 'published';
    raise exception 'FAIL: published wording was edited';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM008' then
      raise exception 'FAIL: unexpected edit error % %', sqlstate, sqlerrm;
    end if;
  end;
end $$;
select 'published_wording_is_immutable' as check, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- One published version per line
-- ---------------------------------------------------------------------------
begin;
do $$
declare
  v_line_id uuid;
begin
  select id into v_line_id from public.narration_lines where slug = 'idle-1';
  begin
    insert into public.narration_line_versions
      (line_id, version, status, text, text_ur, text_hash, published_at)
    values (
      v_line_id, 2, 'published', 'Take all the time you need.',
      'جتنا وقت چاہیں لیں۔',
      nano_internal.narration_text_hash('Take all the time you need.', 'x'),
      timezone('utc', now())
    );
    raise exception 'FAIL: two versions of one line are published';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> '23505' then
      raise exception 'FAIL: unexpected second-publish error % %', sqlstate, sqlerrm;
    end if;
  end;
end $$;
select 'one_published_version_per_line' as check, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- New wording retires the old, and the old recording is not offered for it
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

-- An approved recording of version 1 exists and is delivered.
insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
   provider_id, voice_id, feature, status, moderation, storage_bucket,
   storage_path, content_type, byte_size, checksum, completed_at)
values
  ('voice', 'narration_idle-1', 'en', '1:1', 'Take your time.', 'v1',
   nano_internal.generated_asset_hash(
     'voice', 'narration_idle-1', 'en', '1:1', 'Take your time.', 'v1', 'aoede'
   ),
   'gemini_voice_aoede', 'aoede', 'companion', 'ready', 'approved',
   'generated-assets', 'voice/narration_idle-1/en/hash.wav', 'audio/wav',
   4096, 'sha256:idle', timezone('utc', now()));

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

select 'approved_recording_is_delivered' as check,
  (select storage_path from public.list_narration_lines('en') where slug = 'idle-1')
    = 'voice/narration_idle-1/en/hash.wav' as ok;

-- Only for the language it was recorded in.
select 'urdu_never_gets_english_audio' as check,
  (select storage_path from public.list_narration_lines('ur') where slug = 'idle-1')
    is null as ok;

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $$
declare
  v_draft jsonb;
begin
  v_draft := public.create_narration_line_draft(
    'idle-1', 'Take all the time you need.', 'جتنا وقت چاہیں لیں۔'
  );
  perform public.publish_narration_line_version((v_draft->>'id')::uuid);

  if (select count(*) from public.narration_line_versions v
      join public.narration_lines l on l.id = v.line_id
      where l.slug = 'idle-1' and v.status = 'published') <> 1 then
    raise exception 'FAIL: publishing did not retire the previous wording';
  end if;
  if (select status from public.narration_line_versions v
      join public.narration_lines l on l.id = v.line_id
      where l.slug = 'idle-1' and v.version = 1) <> 'retired' then
    raise exception 'FAIL: the previous version was not retired';
  end if;
end $$;

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

-- The old file still exists, but it says the old words, so it is not offered for
-- the new ones. A learner reads the new caption and hears nothing.
select 'old_recording_is_not_offered_for_new_wording' as check,
  (select line_text from public.list_narration_lines('en') where slug = 'idle-1')
    = 'Take all the time you need.'
  and (select storage_path from public.list_narration_lines('en')
       where slug = 'idle-1') is null as ok;
rollback;

-- ---------------------------------------------------------------------------
-- A line authored in one language only
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $$
declare
  v_draft jsonb;
begin
  v_draft := public.create_narration_line_draft(
    'english-only', 'This line has no Urdu yet.', null, 'en'
  );
  perform public.publish_narration_line_version((v_draft->>'id')::uuid);

  begin
    perform public.request_narration_line('english-only', 'ur');
    raise exception 'FAIL: an unauthored language was recorded';
  exception when others then
    if sqlerrm like '%FAIL%' then raise; end if;
    if sqlstate <> 'NM007' then
      raise exception 'FAIL: unexpected language error % %', sqlstate, sqlerrm;
    end if;
  end;

  if (public.request_narration_line('english-only', 'en')->>'reused')::boolean then
    raise exception 'FAIL: the authored language was refused';
  end if;
end $$;

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

-- An Urdu reader is not shown an English-only line at all, rather than being
-- shown English text under an Urdu interface.
select 'urdu_reader_does_not_see_english_only_line' as check,
  not exists (
    select 1 from public.list_narration_lines('ur') where slug = 'english-only'
  ) as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Nothing above left anything behind
-- ---------------------------------------------------------------------------
select 'no_test_rows_remain' as check,
  (select count(*) from public.generated_assets) = 0
  and (select count(*) from public.narration_lines) = 9
  and (select count(*) from public.narration_line_versions
       where status = 'published') = 9
  and (select count(*) from public.narration_voices) = 1 as ok;
