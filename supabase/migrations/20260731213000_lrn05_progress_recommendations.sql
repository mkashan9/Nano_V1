-- LRN-05: learning progress summary and next-up recommendations.
--
-- Both are read models layered on public.learning_catalog, which is already
-- security_invoker. That is the whole security argument: a recommendation can
-- only ever name a row the learner was allowed to read in the first place, so
-- locked, unpublished, and ineligible content cannot leak through a suggestion.
-- No client-side filter stands in for the server here.

-- The catalog gains a single activity timestamp so both read models can order by
-- "what the learner touched last" without guessing.
drop view if exists public.learning_next_up;
drop view if exists public.learning_progress_summary;
drop view if exists public.learning_catalog;
create view public.learning_catalog with (security_invoker = true) as
select
  s.id                as subject_id,
  s.slug              as subject_slug,
  s.sort_order        as subject_order,
  sv.id               as subject_version_id,
  sv.version          as subject_version,
  sv.title            as subject_title,
  sv.title_ur         as subject_title_ur,
  sv.summary          as subject_summary,
  sv.world_color_hex,
  t.id                as topic_id,
  t.slug              as topic_slug,
  t.sort_order        as topic_order,
  tv.id               as topic_version_id,
  tv.version          as topic_version,
  tv.title            as topic_title,
  tv.title_ur         as topic_title_ur,
  tv.objectives,
  tv.estimated_minutes,
  tv.resources,
  tv.duration_seconds,
  tv.completion_threshold,
  tv.video_provider,
  tv.video_ref,
  tv.captions,
  tv.chapters,
  tv.seek_policy,
  coalesce(lp.status, 'not_started') as progress_status,
  coalesce(lp.progress, 0)           as progress,
  coalesce(lp.resume_seconds, 0)     as resume_seconds,
  coalesce(lp.watched_seconds, 0)    as watched_seconds,
  greatest(
    lp.completed_at,
    lp.last_heartbeat_at,
    lp.updated_at
  )                                  as last_activity_at,
  nullif(blocking.titles, '{}')                     as blocking_titles,
  coalesce(array_length(blocking.titles, 1), 0) > 0 as is_locked
from public.topic_versions tv
join public.topics t on t.id = tv.topic_id
join public.subject_versions sv on sv.id = tv.subject_version_id
join public.learning_subjects s on s.id = t.subject_id
left join public.learning_progress lp
  on lp.topic_version_id = tv.id and lp.user_id = auth.uid()
left join lateral (
  select nano_internal.topic_lock_titles(tv.id) as titles
) blocking on true;

comment on view public.learning_catalog is
  'LRN-01..05 catalog read model: eligibility and drafts via the caller''s RLS, '
  'lock state from nano_internal.topic_lock_titles, playback metadata, '
  'chapters, seeking policy, and last activity.';

grant select on public.learning_catalog to authenticated, service_role;

-- One row per subject the learner can see, counting only what they can see.
create view public.learning_progress_summary with (security_invoker = true) as
select
  lc.subject_id,
  lc.subject_slug,
  lc.subject_order,
  lc.subject_title,
  lc.subject_title_ur,
  lc.world_color_hex,
  count(*)::integer as topics_total,
  count(*) filter (where lc.progress_status = 'completed')::integer
    as topics_completed,
  count(*) filter (where lc.progress_status = 'in_progress')::integer
    as topics_in_progress,
  count(*) filter (where lc.is_locked)::integer as topics_locked,
  coalesce(sum(lc.watched_seconds), 0)::integer as watched_seconds,
  max(lc.last_activity_at) as last_activity_at
from public.learning_catalog lc
group by
  lc.subject_id,
  lc.subject_slug,
  lc.subject_order,
  lc.subject_title,
  lc.subject_title_ur,
  lc.world_color_hex;

comment on view public.learning_progress_summary is
  'LRN-05 per-subject progress for the calling learner. Owner-scoped through '
  'learning_catalog: another learner''s progress is invisible, and locked or '
  'ineligible content is never counted.';

grant select on public.learning_progress_summary to authenticated, service_role;

-- What to offer next, and why.
--
-- Order: something already started (most recent first), then the next topic in
-- a subject the learner has made progress in, then a subject they have not
-- opened. Finished topics are gone, locked topics never appear.
create view public.learning_next_up with (security_invoker = true) as
with visible as (
  select * from public.learning_catalog
),
subject_state as (
  select
    subject_id,
    max(last_activity_at) as subject_last_activity_at,
    count(*) filter (where progress_status <> 'not_started') as touched
  from visible
  group by subject_id
),
candidates as (
  select
    v.subject_id,
    v.subject_slug,
    v.subject_order,
    v.subject_title,
    v.subject_title_ur,
    v.world_color_hex,
    v.topic_id,
    v.topic_slug,
    v.topic_order,
    v.topic_version_id,
    v.topic_title,
    v.topic_title_ur,
    v.estimated_minutes,
    v.duration_seconds,
    v.watched_seconds,
    v.resume_seconds,
    v.progress,
    v.progress_status,
    v.last_activity_at,
    ss.subject_last_activity_at,
    case
      when v.progress_status = 'in_progress' then 'resume'
      when coalesce(ss.touched, 0) > 0 then 'next_in_subject'
      else 'new_subject'
    end as reason
  from visible v
  join subject_state ss on ss.subject_id = v.subject_id
  where not v.is_locked
    and v.progress_status <> 'completed'
)
select
  c.*,
  row_number() over (
    order by
      case c.reason
        when 'resume' then 1
        when 'next_in_subject' then 2
        else 3
      end,
      c.last_activity_at desc nulls last,
      c.subject_last_activity_at desc nulls last,
      c.subject_order,
      c.topic_order
  )::integer as rank
from candidates c;

comment on view public.learning_next_up is
  'LRN-05 ranked next-up suggestions for the calling learner with a reason. '
  'Built on learning_catalog, so a suggestion can only name a topic the learner '
  'is already allowed to open: never locked, unpublished, or ineligible.';

grant select on public.learning_next_up to authenticated, service_role;

update public.app_health
set schema_version = 'LRN-05',
    notes = 'Per-subject progress summary and ranked next-up recommendations',
    updated_at = timezone('utc', now())
where id = 'default';
