-- MED-04 adversarial checks: what a curator may author, what a shape changes,
-- what a learner may see, and — the part clips actually forced — what happens to
-- a job nobody finished.
--
-- Every block rolls back, so the three seeded reactions survive the run.

-- ---------------------------------------------------------------------------
-- A request uses the published direction, once per shape
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med04$
declare
  v_first jsonb;
  v_again jsonb;
  v_tall jsonb;
  v_used integer;
begin
  v_first := public.request_reaction_clip('celebration_celebration', '1:1');

  if (v_first->>'reused')::boolean then
    raise exception 'FAIL: a first clip reported reuse';
  end if;
  -- The slot is the reaction plus Dart's tier name, because that is what the app
  -- will look up. A slot that does not round-trip is a clip nobody ever sees.
  if v_first->'asset'->>'slot' <> 'celebration_celebration_shortClip' then
    raise exception 'FAIL: wrong slot %', v_first->'asset'->>'slot';
  end if;
  -- The direction comes from the database, not from the caller.
  if v_first->'asset'->>'prompt' not like 'A small round friendly companion%' then
    raise exception 'FAIL: wrong direction %', v_first->'asset'->>'prompt';
  end if;
  if v_first->'asset'->>'provider_id' <> 'gemini_veo_video' then
    raise exception 'FAIL: wrong provider %', v_first->'asset'->>'provider_id';
  end if;
  -- A clip is silent, so it is stored once and not per language.
  if v_first->'asset'->>'locale' <> 'en' then
    raise exception 'FAIL: a silent clip was split by language';
  end if;

  select requests_count into v_used
  from public.generation_usage
  where scope = 'platform' and scope_key = '' and kind = 'video'
    and usage_date = (timezone('utc', now()))::date;
  if coalesce(v_used, 0) <> 1 then
    raise exception 'FAIL: a new clip was not counted (%)', v_used;
  end if;

  v_again := public.request_reaction_clip('celebration_celebration', '1:1');
  if not (v_again->>'reused')::boolean then
    raise exception 'FAIL: the same clip was generated twice';
  end if;

  select requests_count into v_used
  from public.generation_usage
  where scope = 'platform' and scope_key = '' and kind = 'video'
    and usage_date = (timezone('utc', now()))::date;
  if v_used <> 1 then
    raise exception 'FAIL: a reused clip consumed budget (%)', v_used;
  end if;

  -- Framing is direction, not a rendering detail: a tall clip is a real second
  -- job, and the seeded reaction authorises both shapes.
  v_tall := public.request_reaction_clip('celebration_celebration', '9:16');
  if (v_tall->>'reused')::boolean then
    raise exception 'FAIL: a different shape reused the square clip';
  end if;
  if v_tall->'asset'->>'prompt_hash' = v_first->'asset'->>'prompt_hash' then
    raise exception 'FAIL: two shapes share one hash';
  end if;
end $med04$;
select 'clip_request_uses_published_direction' as check_name, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Unauthored shapes, unknown reactions, and malformed slugs
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med04$
begin
  -- guide_greeting is authored square only. A tall version would be the same
  -- direction badly framed, which is worse than no clip.
  begin
    perform public.request_reaction_clip('guide_greeting', '9:16');
    raise exception 'FAIL: an unauthored shape was generated';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM009' then
      raise exception 'FAIL: unexpected shape error % %', sqlstate, sqlerrm;
    end if;
  end;

  begin
    perform public.request_reaction_clip('guide_thinking', '1:1');
    raise exception 'FAIL: a reaction outside the library was generated';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM004' then
      raise exception 'FAIL: unexpected unknown-reaction error %', sqlstate;
    end if;
  end;

  -- A slug that is not a mode and a mood cannot address a reaction, so it is
  -- refused at authoring time rather than becoming a slot nothing looks up.
  begin
    perform public.create_reaction_clip_draft('justOneWord', 'Some direction.');
    raise exception 'FAIL: a malformed slug was authored';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM009' then
      raise exception 'FAIL: unexpected slug error % %', sqlstate, sqlerrm;
    end if;
  end;

  if exists (select 1 from public.generated_assets where kind = 'video') then
    raise exception 'FAIL: a refused clip still created a row';
  end if;
  if exists (select 1 from public.generation_usage where kind = 'video') then
    raise exception 'FAIL: a refused clip still charged a budget';
  end if;
end $med04$;
select 'unauthored_shape_and_reaction_are_refused' as check_name, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Authoring is a curator's job only
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

do $med04$
begin
  begin
    perform public.create_reaction_clip_draft('guide_idle', 'Learner direction.');
    raise exception 'FAIL: a learner authored a clip';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM001' then
      raise exception 'FAIL: unexpected authoring error %', sqlstate;
    end if;
  end;

  begin
    perform public.request_reaction_clip('celebration_celebration', '1:1');
    raise exception 'FAIL: a learner requested a clip';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM001' then
      raise exception 'FAIL: unexpected request error %', sqlstate;
    end if;
  end;

  -- Worker-only surfaces are worker-only, not admin-or-worker: they name provider
  -- job handles, which is authoring detail.
  begin
    perform public.list_pending_generated_assets();
    raise exception 'FAIL: a learner listed pending jobs';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate not in ('NM003', '42501') then
      raise exception 'FAIL: unexpected pending error %', sqlstate;
    end if;
  end;
end $med04$;

-- The library itself is invisible, drafts and direction included.
select 'learner_sees_no_clip_library' as check_name,
  (select count(*) from public.reaction_clips) = 0
  and (select count(*) from public.reaction_clip_versions) = 0 as ok;

select 'nobody_signed_in_can_edit_clips' as check_name,
  not has_table_privilege('authenticated', 'public.reaction_clips', 'update')
  and not has_table_privilege(
    'authenticated', 'public.reaction_clip_versions', 'insert'
  ) as ok;

-- What a learner *may* read: nothing, because nothing is approved. An empty
-- answer is ordinary — every reaction already has local art.
select 'learner_sees_no_unapproved_clips' as check_name,
  (select count(*) from public.list_reaction_clips()) = 0 as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Published direction cannot be edited under an approved clip
-- ---------------------------------------------------------------------------
begin;
do $med04$
begin
  begin
    update public.reaction_clip_versions
    set direction = 'Something else entirely.'
    where status = 'published';
    raise exception 'FAIL: published direction was edited';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM008' then
      raise exception 'FAIL: unexpected edit error % %', sqlstate, sqlerrm;
    end if;
  end;

  -- Re-framing a published clip is the same problem wearing a different hat: the
  -- approved file was made for the shapes that were authorised at the time.
  begin
    update public.reaction_clip_versions
    set aspect_ratios = array['1:1', '16:9']
    where status = 'published' and array_length(aspect_ratios, 1) = 1;
    raise exception 'FAIL: published shapes were edited';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> 'NM008' then
      raise exception 'FAIL: unexpected shape edit error %', sqlstate;
    end if;
  end;
end $med04$;
select 'published_direction_is_immutable' as check_name, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- One published version per reaction
-- ---------------------------------------------------------------------------
begin;
do $med04$
declare
  v_clip_id uuid;
begin
  select id into v_clip_id
  from public.reaction_clips where slug = 'guide_greeting';
  begin
    insert into public.reaction_clip_versions
      (clip_id, version, status, direction, aspect_ratios, duration_seconds,
       direction_hash, published_at)
    values (
      v_clip_id, 2, 'published', 'A different wave entirely.', array['1:1'], 3,
      nano_internal.reaction_clip_hash('A different wave entirely.', 3),
      timezone('utc', now())
    );
    raise exception 'FAIL: two versions of one reaction are published';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate <> '23505' then
      raise exception 'FAIL: unexpected second-publish error % %', sqlstate, sqlerrm;
    end if;
  end;
end $med04$;
select 'one_published_version_per_reaction' as check_name, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- New direction retires the old, and the old clip is not offered for it
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

-- An approved clip of version 1 exists and is delivered.
insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
   provider_id, feature, status, moderation, storage_bucket, storage_path,
   content_type, byte_size, checksum, completed_at)
select
  'video', 'guide_greeting_shortClip', 'en', '1:1', rcv.direction, 'v1',
  nano_internal.generated_asset_hash(
    'video', 'guide_greeting_shortClip', 'en', '1:1', rcv.direction, 'v1', null
  ),
  'gemini_veo_video', 'companion', 'ready', 'approved',
  'generated-assets', 'video/guide_greeting_shortClip/en/hash.mp4', 'video/mp4',
  512000, 'sha256:greeting-clip', timezone('utc', now())
from public.reaction_clip_versions rcv
join public.reaction_clips rc on rc.id = rcv.clip_id
where rc.slug = 'guide_greeting' and rcv.status = 'published';

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

select 'approved_clip_is_delivered' as check_name,
  (select storage_path from public.list_reaction_clips()
   where slug = 'guide_greeting')
    = 'video/guide_greeting_shortClip/en/hash.mp4'
  -- The read side carries no direction at all: a prompt is authoring detail.
  and not exists (
    select 1
    from information_schema.columns
    where table_name = 'reaction_clips' and column_name = 'direction'
  ) as ok;

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med04$
declare
  v_draft jsonb;
begin
  v_draft := public.create_reaction_clip_draft(
    'guide_greeting', 'A slower wave with a longer settle.', array['1:1'], 4
  );
  perform public.publish_reaction_clip_version((v_draft->>'id')::uuid);

  if (select count(*) from public.reaction_clip_versions v
      join public.reaction_clips c on c.id = v.clip_id
      where c.slug = 'guide_greeting' and v.status = 'published') <> 1 then
    raise exception 'FAIL: publishing did not retire the previous direction';
  end if;
  if (select status from public.reaction_clip_versions v
      join public.reaction_clips c on c.id = v.clip_id
      where c.slug = 'guide_greeting' and v.version = 1) <> 'retired' then
    raise exception 'FAIL: the previous version was not retired';
  end if;
end $med04$;

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

-- The old file still exists, but it is footage of the old direction, so it is not
-- offered under the new one. That reaction quietly goes back to local art.
select 'old_clip_is_not_offered_for_new_direction' as check_name,
  not exists (
    select 1 from public.list_reaction_clips() where slug = 'guide_greeting'
  ) as ok;
rollback;

-- ---------------------------------------------------------------------------
-- A job nobody finished does not block its slot forever
-- ---------------------------------------------------------------------------
-- This is the failure clips introduce. An image takes two seconds and a crash is
-- invisible; a clip takes minutes, and a worker that dies leaves the row
-- `generating` — which the reuse index then treats as a perfectly good answer.
--
-- Planting the abandoned state happens before the role switch: nobody signed in,
-- including a superadmin, has write access to `generated_assets`. That refusal is
-- correct, and the suite asserts it by refusing to use `authenticated` for it.
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
select (public.request_reaction_clip('celebration_celebration', '1:1')
  -> 'asset' ->> 'id')::uuid as asset_id
into temporary table _med04_abandoned;

reset role;
update public.generated_assets
set status = 'generating',
    claimed_at = timezone('utc', now()) - interval '30 minutes',
    claim_expires_at = timezone('utc', now()) - interval '10 minutes',
    attempts_count = 1,
    provider_job_id = 'operations/abandoned'
where id = (select asset_id from _med04_abandoned);

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med04$
declare
  v_after jsonb;
  v_used integer;
begin
  v_after := public.request_reaction_clip('celebration_celebration', '1:1');

  -- Still a reuse: the ask was charged once already and must not be charged
  -- again just because a worker crashed.
  if not (v_after->>'reused')::boolean then
    raise exception 'FAIL: a recovered job was charged as a new one';
  end if;
  if v_after->'asset'->>'status' <> 'requested' then
    raise exception 'FAIL: an abandoned job is still % ',
      v_after->'asset'->>'status';
  end if;
  if v_after->'asset'->>'provider_job_id' is not null then
    raise exception 'FAIL: a dead job handle survived the release';
  end if;

  select requests_count into v_used
  from public.generation_usage
  where scope = 'platform' and scope_key = '' and kind = 'video'
    and usage_date = (timezone('utc', now()))::date;
  if v_used <> 1 then
    raise exception 'FAIL: recovery double-charged (%)', v_used;
  end if;
end $med04$;
select 'an_abandoned_job_is_returned_to_the_queue' as check_name, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- A job that is genuinely running is left alone
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
select (public.request_reaction_clip('celebration_celebration', '1:1')
  -> 'asset' ->> 'id')::uuid as asset_id
into temporary table _med04_live;

reset role;
update public.generated_assets
set status = 'generating',
    claimed_at = timezone('utc', now()),
    claim_expires_at = timezone('utc', now()) + interval '15 minutes',
    attempts_count = 1,
    provider_job_id = 'operations/alive'
where id = (select asset_id from _med04_live);

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med04$
declare
  v_after jsonb;
begin
  v_after := public.request_reaction_clip('celebration_celebration', '1:1');
  if v_after->'asset'->>'status' <> 'generating' then
    raise exception 'FAIL: a live job was taken away from its worker';
  end if;
  if v_after->'asset'->>'provider_job_id' <> 'operations/alive' then
    raise exception 'FAIL: a live job lost its handle';
  end if;
end $med04$;
select 'a_live_job_is_left_alone' as check_name, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- A job that has had its chances is failed, not retried forever
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';
select (public.request_reaction_clip('celebration_celebration', '1:1')
  -> 'asset' ->> 'id')::uuid as asset_id
into temporary table _med04_exhausted;

reset role;
update public.generated_assets
set status = 'generating',
    claim_expires_at = timezone('utc', now()) - interval '10 minutes',
    attempts_count = 3
where id = (select asset_id from _med04_exhausted);

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med04$
declare
  v_after jsonb;
  v_id uuid;
  v_used integer;
begin
  select asset_id into v_id from _med04_exhausted;
  v_after := public.request_reaction_clip('celebration_celebration', '1:1');

  -- The old row is failed and leaves the reuse index, so this ask is a fresh job
  -- and is charged like one. Retrying a provider forever would be a way to spend
  -- a budget on nothing at all.
  if (v_after->>'reused')::boolean then
    raise exception 'FAIL: an exhausted job was reused';
  end if;
  if (select error_code from public.generated_assets where id = v_id)
     <> 'GENERATION_ABANDONED' then
    raise exception 'FAIL: an exhausted job was not failed properly';
  end if;

  select requests_count into v_used
  from public.generation_usage
  where scope = 'platform' and scope_key = '' and kind = 'video'
    and usage_date = (timezone('utc', now()))::date;
  if v_used <> 2 then
    raise exception 'FAIL: a genuinely new job was not charged (%)', v_used;
  end if;
end $med04$;
select 'an_exhausted_job_is_failed_not_retried' as check_name, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Progress keeps a job alive; only the worker may report it
-- ---------------------------------------------------------------------------
begin;
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","role":"authenticated"}';

do $med04$
declare
  v_first jsonb;
  v_id uuid;
begin
  v_first := public.request_reaction_clip('celebration_celebration', '1:1');
  v_id := (v_first->'asset'->>'id')::uuid;

  -- An admin is not a worker, even though an admin started the request.
  begin
    perform public.record_generated_asset_progress(v_id, 'operations/x', 20);
    raise exception 'FAIL: an admin reported provider progress';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlstate not in ('NM003', '42501') then
      raise exception 'FAIL: unexpected progress error %', sqlstate;
    end if;
  end;
end $med04$;
select 'progress_is_worker_only' as check_name, true as ok;
rollback;

begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

do $med04$
declare
  v_id uuid;
  v_expiry timestamptz;
  v_pending jsonb;
begin
  insert into public.generated_assets
    (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
     provider_id, feature, status, claim_expires_at)
  values
    ('video', 'celebration_celebration_shortClip', 'en', '1:1', 'a clip', 'v1',
     'hash-progress-test', 'gemini_veo_video', 'companion', 'generating',
     timezone('utc', now()) + interval '1 minute')
  returning id into v_id;

  -- A job that is demonstrably alive should not be taken away from the worker
  -- watching it, so checking in pushes the expiry out.
  perform public.record_generated_asset_progress(v_id, 'operations/live', 30);

  select claim_expires_at into v_expiry
  from public.generated_assets where id = v_id;
  if v_expiry <= timezone('utc', now()) + interval '10 minutes' then
    raise exception 'FAIL: progress did not renew the claim (%)', v_expiry;
  end if;

  -- Not due yet: polling every second is how a quota is spent on questions.
  v_pending := public.list_pending_generated_assets();
  if v_pending @> jsonb_build_array(jsonb_build_object('id', v_id)) then
    raise exception 'FAIL: a job that is not due was offered for polling';
  end if;

  update public.generated_assets
  set poll_after = timezone('utc', now()) - interval '1 second'
  where id = v_id;

  v_pending := public.list_pending_generated_assets();
  if jsonb_array_length(v_pending) < 1 then
    raise exception 'FAIL: a due job was not offered for polling';
  end if;

  -- Finishing clears the schedule, so nothing keeps polling a finished job.
  perform public.record_generated_asset_result(
    v_id, 'generated-assets', 'video/x/en/hash.mp4', 'video/mp4',
    512000, 'sha256:done'
  );
  if (select poll_after from public.generated_assets where id = v_id)
     is not null then
    raise exception 'FAIL: a finished job is still scheduled for polling';
  end if;
end $med04$;
select 'progress_renews_and_completion_clears' as check_name, true as ok;
rollback;

-- ---------------------------------------------------------------------------
-- A clip is language-neutral
-- ---------------------------------------------------------------------------
begin;
set local role service_role;
set local request.jwt.claims = '{"role":"service_role"}';

insert into public.generated_assets
  (kind, slot, locale, aspect_ratio, prompt, prompt_version, prompt_hash,
   provider_id, feature, status, moderation, storage_bucket, storage_path,
   content_type, byte_size, checksum, completed_at)
select
  'video', 'celebration_celebration_shortClip', 'en', '1:1', rcv.direction, 'v1',
  nano_internal.generated_asset_hash(
    'video', 'celebration_celebration_shortClip', 'en', '1:1', rcv.direction,
    'v1', null
  ),
  'gemini_veo_video', 'companion', 'ready', 'approved',
  'generated-assets', 'video/celebration_celebration_shortClip/en/hash.mp4',
  'video/mp4', 512000, 'sha256:celebration-clip', timezone('utc', now())
from public.reaction_clip_versions rcv
join public.reaction_clips rc on rc.id = rcv.clip_id
where rc.slug = 'celebration_celebration' and rcv.status = 'published';

set local role authenticated;
set local request.jwt.claims =
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}';

-- No locale argument exists, and that is the point: an Urdu learner sees the same
-- clip an English learner does, because it has no words in it to be wrong.
select 'a_clip_has_no_language' as check_name,
  (select count(*) from public.list_reaction_clips()
   where slug = 'celebration_celebration') = 1
  and (select mode from public.list_reaction_clips()
       where slug = 'celebration_celebration') = 'celebration' as ok;
rollback;

-- ---------------------------------------------------------------------------
-- Nothing above left anything behind
-- ---------------------------------------------------------------------------
select 'no_test_rows_remain' as check_name,
  (select count(*) from public.generated_assets) = 0
  and (select count(*) from public.reaction_clips) = 3
  and (select count(*) from public.reaction_clip_versions
       where status = 'published') = 3
  and (select count(*) from public.generation_usage where kind = 'video') = 0
    as ok;
