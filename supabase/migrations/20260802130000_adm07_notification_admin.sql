-- ADM-07: platform notification template catalog (draft / publish / disable).
-- Student inbox (STU-06), push delivery (NOT-01), quiet hours (NOT-02) stay deferred.

create table if not exists public.notification_templates (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique
    check (slug ~ '^[a-z][a-z0-9_]{1,62}$'),
  category text not null default 'system'
    check (category in (
      'learning', 'gamification', 'account', 'school', 'system'
    )),
  title_en text not null,
  title_ur text not null default '',
  body_en text not null default '',
  body_ur text not null default '',
  deep_link_template text not null default '/',
  channel_policy text not null default 'in_app'
    check (channel_policy in ('in_app', 'push', 'both')),
  status text not null default 'draft'
    check (status in ('draft', 'published', 'archived')),
  enabled boolean not null default true,
  mandatory boolean not null default false,
  sort_order integer not null default 100,
  published_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

comment on table public.notification_templates is
  'ADM-07 curated notification copy. Inbox fan-out is STU-06; push is NOT-01.';

create index if not exists notification_templates_status_idx
  on public.notification_templates (status, enabled);
create index if not exists notification_templates_category_idx
  on public.notification_templates (category, sort_order);

drop trigger if exists notification_templates_set_updated_at
  on public.notification_templates;
create trigger notification_templates_set_updated_at
  before update on public.notification_templates
  for each row execute function public.set_updated_at();

alter table public.notification_templates enable row level security;

drop policy if exists notification_templates_select_admin
  on public.notification_templates;
create policy notification_templates_select_admin
  on public.notification_templates
  for select to authenticated
  using (nano_internal.is_platform_admin());

revoke all on table public.notification_templates from public, anon;
grant select on table public.notification_templates
  to authenticated, service_role;

insert into public.notification_templates
  (id, slug, category, title_en, title_ur, body_en, body_ur,
   deep_link_template, channel_policy, status, enabled, mandatory,
   sort_order, published_at)
values
  (
    '70000000-0000-0000-0000-000000000001',
    'marks_published',
    'school',
    'Marks published',
    'نمبر شائع',
    'New marks are ready to view.',
    'نئے نمبر دیکھنے کے لیے تیار ہیں۔',
    '/flex/marks',
    'both',
    'published',
    true,
    false,
    10,
    timezone('utc', now())
  ),
  (
    '70000000-0000-0000-0000-000000000002',
    'achievement_unlocked',
    'gamification',
    'Achievement unlocked',
    'کامیابی ملی',
    'You earned a new badge.',
    'آپ نے نیا بیج حاصل کیا۔',
    '/profile',
    'in_app',
    'published',
    true,
    false,
    20,
    timezone('utc', now())
  ),
  (
    '70000000-0000-0000-0000-000000000003',
    'account_security',
    'account',
    'Security notice',
    'سیکیورٹی اطلاع',
    'Something changed on your account.',
    'آپ کے اکاؤنٹ میں تبدیلی ہوئی۔',
    '/',
    'both',
    'published',
    true,
    true,
    30,
    timezone('utc', now())
  ),
  (
    '70000000-0000-0000-0000-000000000004',
    'weekly_digest',
    'learning',
    'Weekly digest',
    'ہفتہ وار خلاصہ',
    'A quiet summary of this week''s learning.',
    'اس ہفتے کی تعلیم کا خلاصہ۔',
    '/learning',
    'in_app',
    'draft',
    true,
    false,
    40,
    null
  )
on conflict (id) do nothing;

create or replace function public.list_notification_templates_admin()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NN010',
      message = 'Notification admin is limited to platform staff.';
  end if;

  return coalesce((
    select jsonb_agg(row_to_json(x)::jsonb order by x.sort_order, x.slug)
    from (
      select
        t.id,
        t.slug,
        t.category,
        t.title_en,
        t.title_ur,
        t.body_en,
        t.body_ur,
        t.deep_link_template,
        t.channel_policy,
        t.status,
        t.enabled,
        t.mandatory,
        t.sort_order,
        t.published_at
      from public.notification_templates t
    ) x
  ), '[]'::jsonb);
end;
$fn$;

revoke all on function public.list_notification_templates_admin()
  from public, anon;
grant execute on function public.list_notification_templates_admin()
  to authenticated, service_role;

create or replace function public.create_notification_template_draft(
  p_slug text,
  p_title_en text,
  p_title_ur text default '',
  p_body_en text default '',
  p_body_ur text default '',
  p_category text default 'system',
  p_deep_link_template text default '/',
  p_channel_policy text default 'in_app',
  p_mandatory boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_row public.notification_templates%rowtype;
  v_slug text := lower(btrim(coalesce(p_slug, '')));
  v_title text := btrim(coalesce(p_title_en, ''));
  v_category text := lower(btrim(coalesce(p_category, 'system')));
  v_channel text := lower(btrim(coalesce(p_channel_policy, 'in_app')));
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NN010',
      message = 'Notification admin is limited to platform staff.';
  end if;

  if v_slug !~ '^[a-z][a-z0-9_]{1,62}$' or v_title = '' then
    raise exception using
      errcode = 'NN011',
      message = 'Template slug and English title are required.';
  end if;

  if v_category not in (
    'learning', 'gamification', 'account', 'school', 'system'
  ) then
    raise exception using
      errcode = 'NN012',
      message = 'Unknown notification category.';
  end if;

  if v_channel not in ('in_app', 'push', 'both') then
    raise exception using
      errcode = 'NN013',
      message = 'Unknown channel policy.';
  end if;

  insert into public.notification_templates (
    slug, category, title_en, title_ur, body_en, body_ur,
    deep_link_template, channel_policy, status, enabled, mandatory,
    sort_order
  ) values (
    v_slug,
    v_category,
    v_title,
    coalesce(p_title_ur, ''),
    coalesce(p_body_en, ''),
    coalesce(p_body_ur, ''),
    coalesce(nullif(btrim(p_deep_link_template), ''), '/'),
    v_channel,
    'draft',
    true,
    coalesce(p_mandatory, false),
    coalesce(
      (select max(sort_order) + 10 from public.notification_templates),
      10
    )
  )
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(),
    'superadmin',
    'create'::public.audit_action_kind,
    'notification_template',
    v_row.id::text,
    jsonb_build_object(
      'slug', v_row.slug,
      'category', v_row.category,
      'title_en', v_row.title_en
    )
  );

  return jsonb_build_object(
    'id', v_row.id,
    'slug', v_row.slug,
    'category', v_row.category,
    'title_en', v_row.title_en,
    'title_ur', v_row.title_ur,
    'body_en', v_row.body_en,
    'body_ur', v_row.body_ur,
    'deep_link_template', v_row.deep_link_template,
    'channel_policy', v_row.channel_policy,
    'status', v_row.status,
    'enabled', v_row.enabled,
    'mandatory', v_row.mandatory,
    'sort_order', v_row.sort_order,
    'published_at', v_row.published_at
  );
end;
$fn$;

revoke all on function public.create_notification_template_draft(
  text, text, text, text, text, text, text, text, boolean
) from public, anon;
grant execute on function public.create_notification_template_draft(
  text, text, text, text, text, text, text, text, boolean
) to authenticated, service_role;

create or replace function public.publish_notification_template(p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_row public.notification_templates%rowtype;
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NN010',
      message = 'Notification admin is limited to platform staff.';
  end if;

  select * into v_row from public.notification_templates
  where id = p_id for update;

  if not found then
    raise exception using
      errcode = 'NN014',
      message = 'Unknown notification template.';
  end if;

  if v_row.status = 'published' and v_row.enabled then
    return jsonb_build_object(
      'id', v_row.id,
      'status', v_row.status,
      'enabled', v_row.enabled
    );
  end if;

  if v_row.status = 'archived' and not v_row.enabled then
    raise exception using
      errcode = 'NN015',
      message = 'Archived templates cannot be republished. Create a new draft.';
  end if;

  if btrim(v_row.title_en) = '' then
    raise exception using
      errcode = 'NN016',
      message = 'Publish requires an English title.';
  end if;

  update public.notification_templates
  set status = 'published',
      enabled = true,
      published_at = coalesce(published_at, timezone('utc', now())),
      updated_at = timezone('utc', now())
  where id = p_id
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value)
  values (
    auth.uid(),
    'superadmin',
    'update'::public.audit_action_kind,
    'notification_template',
    v_row.id::text,
    jsonb_build_object('status', 'published', 'slug', v_row.slug)
  );

  return jsonb_build_object(
    'id', v_row.id,
    'status', v_row.status,
    'enabled', v_row.enabled,
    'published_at', v_row.published_at
  );
end;
$fn$;

revoke all on function public.publish_notification_template(uuid)
  from public, anon;
grant execute on function public.publish_notification_template(uuid)
  to authenticated, service_role;

create or replace function public.disable_notification_template(
  p_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, nano_internal
as $fn$
declare
  v_row public.notification_templates%rowtype;
  v_reason text := btrim(coalesce(p_reason, ''));
begin
  if auth.uid() is null or not nano_internal.is_platform_admin() then
    raise exception using
      errcode = 'NN010',
      message = 'Notification admin is limited to platform staff.';
  end if;

  if v_reason = '' then
    raise exception using
      errcode = 'NN017',
      message = 'A reason is required to disable a notification template.';
  end if;

  select * into v_row from public.notification_templates
  where id = p_id for update;

  if not found then
    raise exception using
      errcode = 'NN014',
      message = 'Unknown notification template.';
  end if;

  if v_row.status = 'archived' and not v_row.enabled then
    return jsonb_build_object(
      'id', v_row.id,
      'status', v_row.status,
      'enabled', v_row.enabled
    );
  end if;

  update public.notification_templates
  set enabled = false,
      status = case
        when status = 'published' then 'archived'
        else status
      end,
      updated_at = timezone('utc', now())
  where id = p_id
  returning * into v_row;

  insert into public.audit_events
    (actor_user_id, actor_role, action, target_type, target_id, new_value, reason)
  values (
    auth.uid(),
    'superadmin',
    'revoke'::public.audit_action_kind,
    'notification_template',
    v_row.id::text,
    jsonb_build_object(
      'status', v_row.status,
      'enabled', v_row.enabled,
      'slug', v_row.slug
    ),
    v_reason
  );

  return jsonb_build_object(
    'id', v_row.id,
    'status', v_row.status,
    'enabled', v_row.enabled
  );
end;
$fn$;

revoke all on function public.disable_notification_template(uuid, text)
  from public, anon;
grant execute on function public.disable_notification_template(uuid, text)
  to authenticated, service_role;
