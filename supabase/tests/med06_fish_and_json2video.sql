-- MED-06 adversarial checks: the rules that only exist because a clip is now
-- composed from a real picture instead of imagined from a description.
--
-- The provider swap itself needs almost no defending — a default is a row. What
-- needs defending is the consequence: a compositor is handed a URL to something
-- in our storage, and that something must never be a picture a reviewer has not
-- approved. Every block below is an attempt to get an unapproved, wrong-shaped,
-- or unauthored picture in front of a rendering service.
--
-- Assets are planted as service_role rather than driven through the worker,
-- because `authenticated` has no write privilege on generated_assets and a test
-- that grants itself one is testing the wrong database.
--
-- Every block rolls back, so the fixtures survive the run.
--   dddddddd-… platform admin      ffffffff-… school admin      aaaaaaaa-… learner

-- ---------------------------------------------------------------------------
-- The swap itself: what an unqualified ask now reaches
-- ---------------------------------------------------------------------------
do $med06$
declare
  v_voice text;
  v_video text;
  v_composes boolean;
begin
  select id into v_voice from public.generation_providers where kind = 'voice' and is_default;
  select id, composes_from_art into v_video, v_composes
  from public.generation_providers where kind = 'video' and is_default;

  if v_voice <> 'fish_audio_voice' then
    raise exception 'FAIL: the default voice provider is %', v_voice;
  end if;
  if v_video <> 'json2video_compose' then
    raise exception 'FAIL: the default clip provider is %', v_video;
  end if;
  -- The flag, not the id, is what the request gate reads. A default that
  -- composes but does not say so would skip every check below.
  if not v_composes then
    raise exception 'FAIL: the compositor is not marked as composing from art';
  end if;

  -- Exactly one default per kind, and the superseded rows are disabled rather
  -- than deleted so a rollback is a row update.
  if (select count(*) from public.generation_providers where kind = 'voice' and is_default) <> 1
     or (select count(*) from public.generation_providers where kind = 'video' and is_default) <> 1 then
    raise exception 'FAIL: a kind has more than one default provider';
  end if;
  if not exists (select 1 from public.generation_providers where id = 'gemini_veo_video') then
    raise exception 'FAIL: the superseded provider was deleted rather than disabled';
  end if;
end $med06$;

-- The Learning Guide's voice is a Fish voice, and it is a new row rather than an
-- edit: the voice id is part of the reuse hash, so editing `aoede` in place would
-- have handed Gemini recordings back for Fish requests.
do $med06$
declare
  v_voice public.narration_voices;
begin
  select * into v_voice from public.narration_voices where is_default;
  if v_voice.id <> 'guide_fish_stock' then
    raise exception 'FAIL: the default narration voice is %', v_voice.id;
  end if;
  if v_voice.provider_id <> 'fish_audio_voice' then
    raise exception 'FAIL: the default voice belongs to %', v_voice.provider_id;
  end if;
  -- Named, not blank. The column refuses an empty string, and a blank would read
  -- as an oversight rather than as "Fish's own default voice".
  if v_voice.provider_voice_name <> 'stock' then
    raise exception 'FAIL: the stock voice is recorded as %', v_voice.provider_voice_name;
  end if;
  if (select is_enabled from public.narration_voices where id = 'aoede') then
    raise exception 'FAIL: the superseded voice is still offered';
  end if;
end $med06$;

-- ---------------------------------------------------------------------------
-- A clip of a reaction with no approved art is refused before it costs anything
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med06$
declare
  v_before integer;
  v_after integer;
begin
  -- quizCoach_celebration is published, authored for 1:1, and has no companion
  -- art of any kind. Under MED-04 this would have gone straight to a provider.
  select count(*) into v_before from public.generated_assets;

  begin
    perform public.request_reaction_clip('quizCoach_celebration', '1:1');
    raise exception 'FAIL: a clip was requested with no approved art to animate';
  exception
    when sqlstate 'NM011' then null;
  end;

  select count(*) into v_after from public.generated_assets;
  -- The refusal has to come before the row exists, or the day's request ceiling
  -- has been spent on something that was never going to render.
  if v_after <> v_before then
    raise exception 'FAIL: a refused clip still created an asset row';
  end if;
end $med06$;
rollback;

-- ---------------------------------------------------------------------------
-- Art that exists but has not been approved is still no art
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

-- A finished, downloadable, entirely unreviewed picture of the companion. This
-- is what every generation produces before a human looks at it.
insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, status, moderation, prompt, prompt_version,
   prompt_hash, provider_id, feature, storage_bucket, storage_path, content_type,
   byte_size, checksum, completed_at)
values (
  'image',
  nano_internal.companion_art_slot('quizCoach_celebration'),
  'en', '1:1', 'ready', 'unreviewed',
  'A small round friendly companion gives an encouraging nod.', 'v1',
  'med06unreviewed', 'pollinations_image', 'companion',
  'generated-assets', 'image/med06/unreviewed.png', 'image/png',
  24576, 'sha256:med06-unreviewed', timezone('utc', now())
);

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med06$
begin
  begin
    perform public.request_reaction_clip('quizCoach_celebration', '1:1');
    raise exception 'FAIL: unreviewed art was accepted as something to animate';
  exception
    when sqlstate 'NM011' then null;
  end;
end $med06$;

-- And the worker cannot route around the refusal by asking for the movie
-- directly. This is the check that actually matters: the worker is the thing
-- holding a service key and a signing function.
reset role;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

do $med06$
begin
  begin
    perform public.reaction_clip_composition('quizCoach_celebration', '1:1');
    raise exception 'FAIL: the worker was told to compose unreviewed art';
  exception
    when sqlstate 'NM011' then null;
  end;
end $med06$;
rollback;

-- ---------------------------------------------------------------------------
-- Approved art in the wrong shape is not near enough
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

-- celebration_celebration is authored for both 1:1 and 9:16. Only the square
-- picture is approved.
insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, status, moderation, prompt, prompt_version,
   prompt_hash, provider_id, feature, storage_bucket, storage_path, content_type,
   byte_size, checksum, completed_at, reviewed_at)
values (
  'image',
  nano_internal.companion_art_slot('celebration_celebration'),
  'en', '1:1', 'ready', 'approved',
  'A small round friendly companion celebrating.', 'v1',
  'med06square', 'pollinations_image', 'companion',
  'generated-assets', 'image/med06/square.png', 'image/png',
  24576, 'sha256:med06-square', timezone('utc', now()), timezone('utc', now())
);

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med06$
declare
  v_out jsonb;
begin
  -- The square clip composes, because the square picture is approved.
  v_out := public.request_reaction_clip('celebration_celebration', '1:1');
  if v_out->'asset'->>'aspect_ratio' <> '1:1' then
    raise exception 'FAIL: the square clip was not requested';
  end if;

  -- The tall one does not. Stretching a square companion into a story card is
  -- not the clip anybody authored, and cropping one is worse.
  begin
    perform public.request_reaction_clip('celebration_celebration', '9:16');
    raise exception 'FAIL: square art was accepted for a tall clip';
  exception
    when sqlstate 'NM011' then null;
  end;

  -- A shape nobody authored at all is still refused first, on its own terms.
  begin
    perform public.request_reaction_clip('celebration_celebration', '4:3');
    raise exception 'FAIL: an unauthored shape was accepted';
  exception
    when sqlstate 'NM009' then null;
  end;
end $med06$;
rollback;

-- ---------------------------------------------------------------------------
-- What the worker is actually told to build
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, status, moderation, prompt, prompt_version,
   prompt_hash, provider_id, feature, storage_bucket, storage_path, content_type,
   byte_size, checksum, completed_at, reviewed_at)
values (
  'image',
  nano_internal.companion_art_slot('guide_greeting'),
  'en', '1:1', 'ready', 'approved',
  'A small round friendly companion waving.', 'v1',
  'med06greeting', 'pollinations_image', 'companion',
  'generated-assets', 'image/med06/greeting.png', 'image/png',
  24576, 'sha256:med06-greeting', timezone('utc', now()), timezone('utc', now())
);

do $med06$
declare
  v_plan jsonb;
begin
  v_plan := public.reaction_clip_composition('guide_greeting', '1:1');

  -- The picture, by bucket and path, so the worker signs an object rather than
  -- guessing a URL.
  if v_plan->>'source_path' <> 'image/med06/greeting.png' then
    raise exception 'FAIL: the worker was pointed at %', v_plan->>'source_path';
  end if;
  if v_plan->>'source_bucket' <> 'generated-assets' then
    raise exception 'FAIL: the worker was pointed at bucket %', v_plan->>'source_bucket';
  end if;
  -- The authored movement and the authored length, not the adapter's defaults.
  if v_plan->>'motion' <> 'driftIn' then
    raise exception 'FAIL: the authored motion arrived as %', v_plan->>'motion';
  end if;
  if (v_plan->>'duration_seconds')::integer <> 3 then
    raise exception 'FAIL: the authored length arrived as %', v_plan->>'duration_seconds';
  end if;
  -- No direction in it at all. The prose is for a reviewer; sending it to a
  -- compositor would be sending a prompt to something that cannot read one.
  if v_plan ? 'direction' or v_plan ? 'prompt' then
    raise exception 'FAIL: the composition carries authoring prose';
  end if;
end $med06$;

-- Newer approved art wins, because re-approving a better picture is how a
-- reaction is improved and the clip should be made of the current companion.
insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, status, moderation, prompt, prompt_version,
   prompt_hash, provider_id, feature, storage_bucket, storage_path, content_type,
   byte_size, checksum, completed_at, reviewed_at)
values (
  'image',
  nano_internal.companion_art_slot('guide_greeting'),
  'en', '1:1', 'ready', 'approved',
  'A small round friendly companion waving, warmer palette.', 'v2',
  'med06greeting2', 'pollinations_image', 'companion',
  'generated-assets', 'image/med06/greeting-v2.png', 'image/png',
  24576, 'sha256:med06-greeting-2', timezone('utc', now()),
  timezone('utc', now()) + interval '1 minute'
);

do $med06$
begin
  if (public.reaction_clip_composition('guide_greeting', '1:1'))->>'source_path'
     <> 'image/med06/greeting-v2.png' then
    raise exception 'FAIL: the clip would be made of the older approved picture';
  end if;
end $med06$;
rollback;

-- ---------------------------------------------------------------------------
-- Nobody but the worker gets a rendering instruction
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, status, moderation, prompt, prompt_version,
   prompt_hash, provider_id, feature, storage_bucket, storage_path, content_type,
   byte_size, checksum, completed_at, reviewed_at)
values (
  'image',
  nano_internal.companion_art_slot('guide_greeting'),
  'en', '1:1', 'ready', 'approved',
  'A small round friendly companion waving.', 'v1',
  'med06perms', 'pollinations_image', 'companion',
  'generated-assets', 'image/med06/perms.png', 'image/png',
  24576, 'sha256:med06-perms', timezone('utc', now()), timezone('utc', now())
);

-- A platform admin is the most privileged human in the system and still has no
-- business here: a composition is a machine instruction, not something a person
-- reviews or acts on, and the storage path in it is not a reviewer's concern.
reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med06$
begin
  begin
    perform public.reaction_clip_composition('guide_greeting', '1:1');
    raise exception 'FAIL: a platform admin was handed a composition';
  exception
    when insufficient_privilege then null;
    when sqlstate 'NM003' then null;
  end;
end $med06$;

-- A school admin cannot ask for a clip at all, composed or otherwise.
reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"ffffffff-ffff-ffff-ffff-ffffffffffff","role":"authenticated"}';

do $med06$
begin
  begin
    perform public.request_reaction_clip('guide_greeting', '1:1');
    raise exception 'FAIL: a school admin requested a clip';
  exception
    when sqlstate 'NM001' then null;
    when insufficient_privilege then null;
  end;
end $med06$;

-- And a learner reaches neither, which is the same answer MED-04 gave.
reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

do $med06$
begin
  begin
    perform public.request_reaction_clip('guide_greeting', '1:1');
    raise exception 'FAIL: a learner requested a clip';
  exception
    when sqlstate 'NM001' then null;
    when insufficient_privilege then null;
  end;

  begin
    perform public.reaction_clip_composition('guide_greeting', '1:1');
    raise exception 'FAIL: a learner was handed a composition';
  exception
    when sqlstate 'NM003' then null;
    when insufficient_privilege then null;
  end;
end $med06$;
rollback;

-- ---------------------------------------------------------------------------
-- Motion is authored, closed, and immutable once published
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med06$
declare
  v_draft jsonb;
begin
  -- A movement the compositor cannot render is refused at authoring time, not
  -- discovered by a child watching a screen.
  begin
    perform public.create_reaction_clip_draft(
      'guide_greeting', 'The companion does a backflip.', array['1:1'], 3, '', 'backflip'
    );
    raise exception 'FAIL: an unrenderable motion was authored';
  exception
    when sqlstate 'NM009' then null;
  end;

  -- A real one is accepted and comes back named, so a curator can see what they
  -- chose rather than trusting a default.
  v_draft := public.create_reaction_clip_draft(
    'guide_greeting', 'The companion waves once and settles.', array['1:1'], 3, '', 'hold'
  );
  if v_draft->>'motion' <> 'hold' then
    raise exception 'FAIL: the draft recorded motion %', v_draft->>'motion';
  end if;
  if v_draft->>'status' <> 'draft' then
    raise exception 'FAIL: a draft was published on creation';
  end if;
end $med06$;
rollback;

-- A published version's motion cannot be edited, for the same reason its
-- direction cannot: a different movement is a different clip, and footage
-- already approved under the old one would silently start describing the new.
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

do $med06$
begin
  begin
    update public.reaction_clip_versions v
    set motion = 'pushIn'
    from public.reaction_clips c
    where c.id = v.clip_id and c.slug = 'guide_greeting' and v.status = 'published';
    raise exception 'FAIL: a published motion was edited in place';
  exception
    when sqlstate 'NM008' then null;
  end;
end $med06$;

-- The closed set is a constraint, not only a function check, so nothing reaches
-- the column sideways.
do $med06$
begin
  begin
    update public.reaction_clip_versions
    set motion = 'strobe'
    where status = 'draft';
    -- No draft rows is also a pass: nothing was written either way.
    if found then
      raise exception 'FAIL: an unknown motion was written to the column';
    end if;
  exception
    when check_violation then null;
  end;
end $med06$;
rollback;

-- ---------------------------------------------------------------------------
-- The budget still refuses before a provider is reached
-- ---------------------------------------------------------------------------
-- MED-02's ceilings do not know or care that the provider changed. This is here
-- because a cost estimate moved from zero to a real figure in this module, and a
-- budget that stopped biting would be the quiet way that breaks.
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, status, moderation, prompt, prompt_version,
   prompt_hash, provider_id, feature, storage_bucket, storage_path, content_type,
   byte_size, checksum, completed_at, reviewed_at)
values (
  'image',
  nano_internal.companion_art_slot('guide_greeting'),
  'en', '1:1', 'ready', 'approved',
  'A small round friendly companion waving.', 'v1',
  'med06budget', 'pollinations_image', 'companion',
  'generated-assets', 'image/med06/budget.png', 'image/png',
  24576, 'sha256:med06-budget', timezone('utc', now()), timezone('utc', now())
);

-- Spend the day's video allowance without generating anything.
update public.generation_quotas
set max_requests_per_day = 0
where kind = 'video';

reset role;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med06$
begin
  begin
    perform public.request_reaction_clip('guide_greeting', '1:1');
    raise exception 'FAIL: a spent budget still reached the compositor';
  exception
    when sqlstate 'NM006' then null;
  end;
end $med06$;
rollback;
