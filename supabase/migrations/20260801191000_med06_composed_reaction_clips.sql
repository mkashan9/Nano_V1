-- MED-06 a reaction clip becomes motion over art a reviewer already approved.
--
-- Under MED-04 a clip was a description handed to a model that imagined footage.
-- Two things were always uncomfortable about that: the companion in the clip was
-- not the companion in the picture, and nobody could say in advance what a child
-- would see. Composing removes both. The clip is the approved picture, moving.
--
-- What a curator authors is therefore no longer only prose. The prose stays —
-- it is what the reaction is *for*, and a reviewer reads it — but the thing that
-- actually renders is a named motion from a closed set. A closed set is the
-- point: a curator cannot author a movement that turns out to be a seizure
-- risk, and a provider cannot interpret the words differently on Tuesday.

-- ---------------------------------------------------------------------------
-- Motion
-- ---------------------------------------------------------------------------
-- Each name says what it renders, not what it is meant to evoke. A compositor
-- has no keyframes, so it cannot make a companion hop; pretending otherwise in
-- the name would leave a curator picking `celebrationHop` and getting a slow
-- push-in. These five are all a compositor can honestly do over one picture.
--
--   hold     no movement at all, a still frame that fades in and out
--   settle   a barely-there drift upward, calm enough for a thinking pause
--   driftIn  the companion arrives from the side and comes to rest
--   pushIn   the strongest move in the set: toward the learner, for a win
--   dip      a small move downward, the closest thing to a nod
alter table public.reaction_clip_versions
  add column if not exists motion text not null default 'settle';

comment on column public.reaction_clip_versions.motion is
  'MED-06 how the approved companion art moves in this clip. A closed set, so a '
  'clip can never render a movement nobody has seen.';

-- Assigned here, before the column becomes immutable below. These three
-- reactions were published under MED-04 and none of them has ever produced a
-- frame, so there is no footage that this could disagree with. From the next
-- statement onward, changing a published motion means publishing a new version.
update public.reaction_clip_versions v
set motion = case c.slug
  when 'guide_greeting' then 'driftIn'
  when 'celebration_celebration' then 'pushIn'
  when 'quizCoach_celebration' then 'dip'
  else v.motion
end
from public.reaction_clips c
where c.id = v.clip_id
  and c.slug in ('guide_greeting', 'celebration_celebration', 'quizCoach_celebration');

alter table public.reaction_clip_versions
  drop constraint if exists reaction_clip_versions_motion_known;
alter table public.reaction_clip_versions
  add constraint reaction_clip_versions_motion_known
  check (motion in ('hold', 'settle', 'driftIn', 'pushIn', 'dip'));

-- Motion joins the list of things a published version cannot change. It decides
-- what a learner sees just as much as the direction does, so it gets the same
-- protection: a different movement is a different clip, and a different clip is
-- a new version.
create or replace function nano_internal.reaction_clip_guard()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  if old.status = 'published' and (
    new.direction is distinct from old.direction
    or new.aspect_ratios is distinct from old.aspect_ratios
    or new.duration_seconds is distinct from old.duration_seconds
    or new.motion is distinct from old.motion
    or new.version is distinct from old.version
    or new.clip_id is distinct from old.clip_id
  ) then
    raise exception using
      errcode = 'NM008',
      message = 'A published reaction clip cannot be edited. Publish a new version.';
  end if;
  return new;
end;
$$;

-- Authoring learns the new field. The old five-argument signature is dropped
-- rather than left beside this one: two overloads that differ only by a
-- defaulted tail argument make every five-argument call ambiguous.
drop function if exists public.create_reaction_clip_draft(text, text, text[], integer, text);

create or replace function public.create_reaction_clip_draft(
  p_slug text,
  p_direction text,
  p_aspect_ratios text[] default array['1:1'],
  p_duration_seconds integer default 4,
  p_notes text default '',
  p_motion text default 'settle'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_clip public.reaction_clips;
  v_slug text := btrim(coalesce(p_slug, ''));
  v_direction text := btrim(coalesce(p_direction, ''));
  v_motion text := btrim(coalesce(p_motion, 'settle'));
  v_shapes text[] := coalesce(p_aspect_ratios, array['1:1']);
  v_duration integer := coalesce(p_duration_seconds, 4);
  v_version integer;
  v_id uuid;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NM001',
      message = 'Only platform admins can author reaction clips.';
  end if;

  if v_slug = '' or v_direction = '' then
    raise exception using
      errcode = 'NM004',
      message = 'A reaction needs a slug and a direction.';
  end if;

  if v_motion not in ('hold', 'settle', 'driftIn', 'pushIn', 'dip') then
    raise exception using
      errcode = 'NM009',
      message = 'That is not a motion this compositor can render.';
  end if;

  select * into v_clip from public.reaction_clips where slug = v_slug;
  if v_clip.id is null then
    raise exception using
      errcode = 'NM004',
      message = 'That reaction is not in the clip library.';
  end if;

  select coalesce(max(version), 0) + 1 into v_version
  from public.reaction_clip_versions
  where clip_id = v_clip.id;

  insert into public.reaction_clip_versions
    (clip_id, version, status, direction, aspect_ratios, duration_seconds,
     motion, direction_hash, created_by)
  values (
    v_clip.id,
    v_version,
    'draft',
    v_direction,
    v_shapes,
    v_duration,
    v_motion,
    nano_internal.reaction_clip_hash(v_direction, v_duration),
    auth.uid()
  )
  returning id into v_id;

  return jsonb_build_object(
    'id', v_id,
    'slug', v_slug,
    'version', v_version,
    'status', 'draft',
    'motion', v_motion
  );
end;
$$;

comment on function public.create_reaction_clip_draft(
  text, text, text[], integer, text, text
) is
  'MED-06 author a reaction clip. The motion is the part that renders; the '
  'direction is what the reaction is for, and what a reviewer reads.';

revoke all on function public.create_reaction_clip_draft(
  text, text, text[], integer, text, text
) from public, anon;
grant execute on function public.create_reaction_clip_draft(
  text, text, text[], integer, text, text
) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Which picture a clip is made of
-- ---------------------------------------------------------------------------
-- The reaction slug is a mode and a mood; the companion's picture for that same
-- mode and mood is the `staticArt` tier of the same key. One function, so the
-- slot the compositor reads can never drift from the slot the client asks for.
create or replace function nano_internal.companion_art_slot(p_slug text)
returns text
language sql
immutable
set search_path = pg_catalog
as $$
  select btrim(coalesce(p_slug, '')) || '_staticArt';
$$;

revoke all on function nano_internal.companion_art_slot(text) from public, anon;
grant execute on function nano_internal.companion_art_slot(text)
  to authenticated, service_role;

-- The approved picture for a reaction in a given shape, or nothing.
--
-- Three conditions, and every one of them is load-bearing. `ready` because a row
-- without a file is not a picture. `approved` because MED-05 made approval the
-- only thing that makes an asset visible, and sending an unreviewed picture to a
-- rendering service would publish it to a third party before a human ever saw
-- it. The exact aspect ratio because a square companion letterboxed into a tall
-- card is not the clip anybody authored — the same reason MED-04 refuses an
-- unauthored shape.
create or replace function nano_internal.approved_companion_art(
  p_slug text,
  p_aspect_ratio text
)
returns public.generated_assets
language sql
stable
set search_path = pg_catalog, public, nano_internal
as $$
  select *
  from public.generated_assets
  where kind = 'image'
    and slot = nano_internal.companion_art_slot(p_slug)
    and aspect_ratio = btrim(coalesce(p_aspect_ratio, '1:1'))
    and status = 'ready'
    and moderation = 'approved'
    and storage_path is not null
  -- Newest approved picture wins: re-approving better art is how a reaction is
  -- improved, and the clip should be made of the current companion.
  order by reviewed_at desc nulls last, created_at desc
  limit 1;
$$;

revoke all on function nano_internal.approved_companion_art(text, text)
  from public, anon;
grant execute on function nano_internal.approved_companion_art(text, text)
  to authenticated, service_role;
