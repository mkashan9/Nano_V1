-- ADM-08: platform analytics — safe aggregates for superadmin /analytics.
-- No analytics_events taxonomy (ANA-01). No school-scoped reports (SCH-07).
-- No email, guardian, marks rows, attendance, actor ids, or display names.

create or replace function public.platform_analytics()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_since timestamptz := timezone('utc', now()) - interval '7 days';
  v_actions jsonb;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NA010',
      message = 'Platform analytics is limited to platform staff.';
  end if;

  select coalesce(jsonb_agg(row_to_json(x)::jsonb order by x.event_count desc), '[]'::jsonb)
  into v_actions
  from (
    select
      ae.action::text as action,
      count(*)::int as event_count
    from public.audit_events ae
    where ae.created_at >= v_since
    group by ae.action
    order by count(*) desc
    limit 8
  ) x;

  return jsonb_build_object(
    'active_school_count', (
      select count(*)::int
      from public.schools
      where status = 'active'::public.school_status
    ),
    'suspended_school_count', (
      select count(*)::int
      from public.schools
      where status = 'suspended'::public.school_status
    ),
    'active_learner_count', (
      select count(*)::int
      from public.profiles
      where account_kind in (
          'school_student'::public.account_kind,
          'independent_student'::public.account_kind
        )
        and status = 'active'::public.membership_status
    ),
    'independent_learner_count', (
      select count(*)::int
      from public.profiles
      where account_kind = 'independent_student'::public.account_kind
        and status = 'active'::public.membership_status
    ),
    'published_subject_count', (
      select count(*)::int
      from public.subject_versions
      where status = 'published'
    ),
    'published_topic_count', (
      select count(*)::int
      from public.topic_versions
      where status = 'published'
    ),
    'live_game_count', (
      select count(*)::int
      from public.game_versions
      where status = 'published' and enabled
    ),
    'published_notification_count', (
      select count(*)::int
      from public.notification_templates
      where status = 'published' and enabled
    ),
    'topic_completions_7d', (
      select count(*)::int
      from public.topic_completions
      where completed_at >= v_since
    ),
    'xp_awards_7d', (
      select count(*)::int
      from public.xp_ledger
      where awarded_at >= v_since
    ),
    'quiz_passes_7d', (
      select count(*)::int
      from public.topic_quiz_progress
      where passed
        and updated_at >= v_since
    ),
    'audit_events_7d', (
      select count(*)::int
      from public.audit_events
      where created_at >= v_since
    ),
    'assets_awaiting_review', (
      select count(*)::int
      from public.generated_assets
      where moderation = 'unreviewed'::public.generated_asset_moderation
        and status = 'ready'::public.generated_asset_status
    ),
    'open_incident_count', (
      select count(*)::int
      from public.security_incidents
      where status = 'open'::public.incident_status
    ),
    'action_breakdown_7d', v_actions,
    'generated_at', timezone('utc', now())
  );
end;
$fn$;

revoke all on function public.platform_analytics() from public, anon;
grant execute on function public.platform_analytics()
  to authenticated, service_role;

comment on function public.platform_analytics() is
  'ADM-08 superadmin analytics: safe platform aggregates and 7-day activity.';
