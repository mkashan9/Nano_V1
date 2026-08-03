-- COM-01: open Communities discovery (Discord-like; not school-gated).
-- Create/join UX deferred to COM-02 / COM-03. Seed public communities for browse.

create table if not exists public.communities (
  id uuid primary key default gen_random_uuid(),
  slug text not null,
  name text not null,
  summary text not null default '',
  rules_text text not null default '',
  visibility text not null default 'public'
    check (visibility in ('public', 'private')),
  status text not null default 'active'
    check (status in ('active', 'suspended', 'archived')),
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint communities_slug_unique unique (slug)
);

comment on table public.communities is
  'COM-01 open communities. No school_id — Communities are not school-gated.';

create index if not exists communities_public_active_idx
  on public.communities (status, visibility, name)
  where status = 'active' and visibility = 'public';

create table if not exists public.community_memberships (
  id uuid primary key default gen_random_uuid(),
  community_id uuid not null references public.communities (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'member'
    check (role in ('owner', 'admin', 'moderator', 'member')),
  status text not null default 'active'
    check (status in ('active', 'pending', 'banned', 'left')),
  joined_at timestamptz not null default timezone('utc', now()),
  constraint community_memberships_unique unique (community_id, user_id)
);

comment on table public.community_memberships is
  'COM-01 membership snapshots for discovery. Join/leave workflows land in COM-03.';

create index if not exists community_memberships_user_idx
  on public.community_memberships (user_id, status);

create index if not exists community_memberships_community_idx
  on public.community_memberships (community_id, status);

alter table public.communities enable row level security;
alter table public.community_memberships enable row level security;

-- Seed discoverable communities (service-owned; no client writes yet).
insert into public.communities (id, slug, name, summary, rules_text, visibility, status)
values
  (
    'a1000000-0000-4000-8000-000000000001',
    'study-circle',
    'Study Circle',
    'Share tips, ask questions, and cheer each other on.',
    'Be kind. No spoilers for quizzes. Report harmful posts.',
    'public',
    'active'
  ),
  (
    'a1000000-0000-4000-8000-000000000002',
    'science-lab',
    'Science Lab',
    'Experiments, curiosity, and cool science finds.',
    'Stay curious. Credit sources. Keep it respectful.',
    'public',
    'active'
  ),
  (
    'a1000000-0000-4000-8000-000000000003',
    'book-nook',
    'Book Nook',
    'What are you reading? Recommend stories to friends.',
    'No hate speech. Spoiler-tag big plot twists.',
    'public',
    'active'
  ),
  (
    'a1000000-0000-4000-8000-000000000004',
    'quiet-focus',
    'Quiet Focus',
    'A private focus club (not listed in Discover).',
    'Members only.',
    'private',
    'active'
  )
on conflict (id) do nothing;

create or replace function public.my_communities()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
begin
  perform nano_internal.assert_communities_allowed();

  return coalesce((
    select jsonb_agg(
      jsonb_build_object(
        'id', c.id,
        'slug', c.slug,
        'name', c.name,
        'summary', c.summary,
        'visibility', c.visibility,
        'status', c.status,
        'member_count', (
          select count(*)::int
          from public.community_memberships m2
          where m2.community_id = c.id
            and m2.status = 'active'
        ),
        'my_role', m.role,
        'my_status', m.status,
        'joined_at', m.joined_at
      )
      order by c.name
    )
    from public.community_memberships m
    join public.communities c on c.id = m.community_id
    where m.user_id = auth.uid()
      and m.status = 'active'
      and c.status = 'active'
  ), '[]'::jsonb);
end;
$$;

revoke all on function public.my_communities() from public, anon;
grant execute on function public.my_communities() to authenticated, service_role;

create or replace function public.discover_public_communities(p_query text default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_q text := nullif(trim(coalesce(p_query, '')), '');
begin
  perform nano_internal.assert_communities_allowed();

  return coalesce((
    select jsonb_agg(row_data order by row_data->>'name')
    from (
      select jsonb_build_object(
        'id', c.id,
        'slug', c.slug,
        'name', c.name,
        'summary', c.summary,
        'visibility', c.visibility,
        'status', c.status,
        'member_count', (
          select count(*)::int
          from public.community_memberships m2
          where m2.community_id = c.id
            and m2.status = 'active'
        ),
        'my_role', m.role,
        'my_status', m.status,
        'joined_at', m.joined_at
      ) as row_data
      from public.communities c
      left join public.community_memberships m
        on m.community_id = c.id
       and m.user_id = auth.uid()
      where c.status = 'active'
        and c.visibility = 'public'
        and (
          v_q is null
          or c.name ilike '%' || v_q || '%'
          or c.slug ilike '%' || v_q || '%'
          or c.summary ilike '%' || v_q || '%'
        )
        and (m.id is null or m.status is distinct from 'active')
    ) q
  ), '[]'::jsonb);
end;
$$;

revoke all on function public.discover_public_communities(text) from public, anon;
grant execute on function public.discover_public_communities(text) to authenticated, service_role;

create or replace function public.get_community_detail(p_community_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, nano_internal
as $$
declare
  v_c public.communities%rowtype;
  v_role text;
  v_status text;
  v_joined timestamptz;
  v_count int := 0;
begin
  perform nano_internal.assert_communities_allowed();

  if p_community_id is null then
    raise exception 'COMMUNITY_REQUIRED' using errcode = 'P0001';
  end if;

  select * into v_c from public.communities where id = p_community_id;
  if not found or v_c.status <> 'active' then
    raise exception 'COMMUNITY_NOT_FOUND' using errcode = 'P0001';
  end if;

  select m.role, m.status, m.joined_at
    into v_role, v_status, v_joined
  from public.community_memberships m
  where m.community_id = p_community_id
    and m.user_id = auth.uid();

  -- Private communities: only visible to members (or pending).
  if v_c.visibility = 'private'
     and coalesce(v_status, '') not in ('active', 'pending') then
    raise exception 'COMMUNITY_NOT_FOUND' using errcode = 'P0001';
  end if;

  select count(*)::int into v_count
  from public.community_memberships m2
  where m2.community_id = p_community_id
    and m2.status = 'active';

  return jsonb_build_object(
    'id', v_c.id,
    'slug', v_c.slug,
    'name', v_c.name,
    'summary', v_c.summary,
    'rules_text', v_c.rules_text,
    'visibility', v_c.visibility,
    'status', v_c.status,
    'member_count', v_count,
    'my_role', v_role,
    'my_status', v_status,
    'joined_at', v_joined,
    'created_at', v_c.created_at
  );
end;
$$;

revoke all on function public.get_community_detail(uuid) from public, anon;
grant execute on function public.get_community_detail(uuid) to authenticated, service_role;
