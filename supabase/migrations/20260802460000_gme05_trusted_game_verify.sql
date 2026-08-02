-- GME-05: trusted game result verification + XP (game_result).

create table if not exists public.game_score_submissions (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.game_sessions (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

comment on table public.game_score_submissions is
  'GME-05 raw client completion envelopes (pre-verify).';

create index if not exists game_score_submissions_session_idx
  on public.game_score_submissions (session_id, created_at desc);

create table if not exists public.game_results (
  session_id uuid primary key references public.game_sessions (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  game_version_id uuid not null references public.game_versions (id),
  verified_score integer not null check (verified_score >= 0),
  duration_ms integer not null check (duration_ms >= 0),
  nonce text not null,
  xp_awarded integer not null default 0,
  verified_at timestamptz not null default timezone('utc', now()),
  unique (user_id, nonce)
);

comment on table public.game_results is
  'GME-05 server-verified game outcomes. One per session; XP via xp_ledger.';

create table if not exists public.rejected_scores (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references public.game_sessions (id) on delete set null,
  user_id uuid references public.profiles (id) on delete set null,
  reason_code text not null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

comment on table public.rejected_scores is
  'GME-05 rejected client scores (bounds, replay, token, etc.).';

alter table public.game_score_submissions enable row level security;
alter table public.game_results enable row level security;
alter table public.rejected_scores enable row level security;

revoke all on table public.game_score_submissions from public, anon, authenticated;
revoke all on table public.game_results from public, anon, authenticated;
revoke all on table public.rejected_scores from public, anon, authenticated;
grant all on table public.game_score_submissions to service_role;
grant all on table public.game_results to service_role;
grant all on table public.rejected_scores to service_role;

-- Learners may read their own verified results.
grant select on table public.game_results to authenticated;
drop policy if exists game_results_select_own on public.game_results;
create policy game_results_select_own on public.game_results
  for select to authenticated
  using (user_id = auth.uid() or nano_internal.is_platform_admin());

update public.xp_award_rules
set amount = 20,
    notes = 'GME-05: one primary award per verified game session.',
    updated_at = timezone('utc', now())
where source_kind = 'game_result';

create or replace function public.report_game_client_completed(
  p_session_id uuid,
  p_play_token text,
  p_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal, extensions
as $fn$
declare
  v_uid uuid := auth.uid();
  v_row public.game_sessions%rowtype;
  v_hash text;
  v_payload jsonb := coalesce(p_payload, '{}'::jsonb);
  v_score integer;
  v_duration integer;
  v_nonce text;
  v_payload_session text;
  v_existing public.game_results%rowtype;
  v_ledger public.xp_ledger;
  v_xp integer := 0;
  v_reason text;
begin
  if v_uid is null then
    raise exception using errcode = 'NS001', message = 'Authentication required.';
  end if;

  if char_length(coalesce(p_play_token, '')) < 16 then
    raise exception using errcode = 'NS147', message = 'Invalid play token.';
  end if;

  if octet_length(v_payload::text) > 8192 then
    raise exception using errcode = 'NS148', message = 'Payload too large.';
  end if;

  select * into v_row
  from public.game_sessions
  where id = p_session_id and user_id = v_uid
  for update;

  if not found then
    raise exception using errcode = 'NS146', message = 'Game session not found.';
  end if;

  select * into v_existing from public.game_results where session_id = v_row.id;
  if found then
    return jsonb_build_object(
      'session_id', v_row.id,
      'status', 'completed',
      'verified', true,
      'verified_score', v_existing.verified_score,
      'xp_awarded', v_existing.xp_awarded,
      'message', 'Result already verified.'
    );
  end if;

  v_hash := encode(digest(p_play_token, 'sha256'), 'hex');
  if v_hash <> v_row.play_token_hash then
    insert into public.rejected_scores (session_id, user_id, reason_code, details)
    values (v_row.id, v_uid, 'invalid_token', jsonb_build_object('hint', 'token'));
    raise exception using errcode = 'NS147', message = 'Invalid play token.';
  end if;

  if v_row.expires_at <= timezone('utc', now()) then
    update public.game_sessions
    set status = 'expired', ended_at = timezone('utc', now())
    where id = v_row.id;
    insert into public.rejected_scores (session_id, user_id, reason_code, details)
    values (v_row.id, v_uid, 'expired', '{}'::jsonb);
    raise exception using errcode = 'NS149', message = 'Game session expired.';
  end if;

  if v_row.status not in ('active', 'completed') then
    insert into public.rejected_scores (session_id, user_id, reason_code, details)
    values (v_row.id, v_uid, 'session_closed', jsonb_build_object('status', v_row.status));
    return jsonb_build_object(
      'session_id', v_row.id,
      'status', v_row.status,
      'verified', false,
      'xp_awarded', 0,
      'message', 'Session already closed.'
    );
  end if;

  insert into public.game_score_submissions (session_id, user_id, payload)
  values (v_row.id, v_uid, v_payload);

  v_score := coalesce((v_payload->>'raw_score')::integer, -1);
  v_duration := coalesce((v_payload->>'duration_ms')::integer, -1);
  v_nonce := nullif(btrim(coalesce(v_payload->>'nonce', '')), '');
  v_payload_session := nullif(btrim(coalesce(v_payload->>'session_id', '')), '');

  if v_payload_session is distinct from v_row.id::text then
    v_reason := 'session_mismatch';
  elsif v_nonce is null or char_length(v_nonce) < 8 then
    v_reason := 'missing_nonce';
  elsif v_score < 0 or v_score > 1000 then
    v_reason := 'score_bounds';
  elsif v_duration < 0 or v_duration > 1800000 then
    v_reason := 'duration_bounds';
  elsif v_duration >
        greatest(0, (extract(epoch from (timezone('utc', now()) - v_row.started_at)) * 1000)::integer + 5000)
  then
    v_reason := 'duration_impossible';
  elsif not nano_internal.game_version_is_eligible(v_row.game_version_id) then
    v_reason := 'version_ineligible';
  end if;

  if v_reason is not null then
    insert into public.rejected_scores (session_id, user_id, reason_code, details)
    values (
      v_row.id, v_uid, v_reason,
      jsonb_build_object(
        'raw_score', v_score,
        'duration_ms', v_duration,
        'nonce', v_nonce
      )
    );
    update public.game_sessions
    set status = 'completed',
        ended_at = timezone('utc', now()),
        client_completed_at = timezone('utc', now()),
        raw_client_payload = v_payload
    where id = v_row.id;
    return jsonb_build_object(
      'session_id', v_row.id,
      'status', 'completed',
      'verified', false,
      'xp_awarded', 0,
      'message', 'Result rejected.'
    );
  end if;

  begin
    insert into public.game_results (
      session_id, user_id, game_version_id,
      verified_score, duration_ms, nonce, xp_awarded
    ) values (
      v_row.id, v_uid, v_row.game_version_id,
      v_score, v_duration, v_nonce, 0
    );
  exception
    when unique_violation then
      insert into public.rejected_scores (session_id, user_id, reason_code, details)
      values (v_row.id, v_uid, 'replay_nonce', jsonb_build_object('nonce', v_nonce));
      return jsonb_build_object(
        'session_id', v_row.id,
        'status', 'completed',
        'verified', false,
        'xp_awarded', 0,
        'message', 'Result rejected.'
      );
  end;

  v_ledger := nano_internal.award_xp(
    v_uid,
    'game_result',
    v_row.id::text,
    null,
    'Verified game session',
    null
  );
  if v_ledger is not null then
    v_xp := v_ledger.amount;
  end if;

  update public.game_results
  set xp_awarded = v_xp
  where session_id = v_row.id;

  update public.game_sessions
  set status = 'completed',
      ended_at = timezone('utc', now()),
      client_completed_at = timezone('utc', now()),
      raw_client_payload = v_payload
  where id = v_row.id;

  insert into public.audit_events
    (actor_user_id, actor_role, school_id, action, target_type, target_id, new_value)
  values (
    v_uid,
    'student',
    v_row.school_id,
    'create'::public.audit_action_kind,
    'game_result',
    v_row.id::text,
    jsonb_build_object(
      'verified_score', v_score,
      'duration_ms', v_duration,
      'xp_awarded', v_xp
    )
  );

  return jsonb_build_object(
    'session_id', v_row.id,
    'status', 'completed',
    'verified', true,
    'verified_score', v_score,
    'xp_awarded', v_xp,
    'message', case
      when v_xp > 0 then 'Result verified. XP awarded.'
      else 'Result verified.'
    end
  );
end;
$fn$;

comment on function public.report_game_client_completed(uuid, text, jsonb) is
  'GME-05 verify client game completion; award game_result XP once.';
