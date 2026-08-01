-- MED-09 the canonical Nori, recorded rather than remembered.
--
-- Character drift is the expected failure of generating a mascot one pose at a
-- time. Each image is plausible alone and the set is not one character: the
-- ears move, the belly patch vanishes, the palette shifts a little each time.
-- A reviewer can only catch that if there is something to compare against, and
-- "the one we approved last week" is not something a reviewer can compare
-- against six weeks later.
--
-- So the sheet is a row. It is versioned, it is locked by a named person, and
-- it names the picture it was written from. A pose is approved or rejected
-- against the sheet that was current when it was reviewed.
--
-- The prose lives in docs/companion/NORI_CHARACTER_SHEET.md and is duplicated
-- here on purpose: a reviewer in admin_web cannot read the repository, and a
-- sheet nobody can see while reviewing is a sheet nobody uses.

create table if not exists public.companion_character_sheet (
  version text primary key,
  summary text not null,
  -- Broken out rather than one blob so the review UI can render "fixed" and
  -- "rejection triggers" as the two lists a reviewer actually reads.
  fixed_traits jsonb not null default '[]'::jsonb,
  variable_traits jsonb not null default '[]'::jsonb,
  rejection_triggers jsonb not null default '[]'::jsonb,
  -- The picture the sheet was written from, and the one every pose is
  -- reference-conditioned on. Nullable because a sheet may be written before
  -- its reference is approved; set once it is.
  reference_asset_id uuid references public.generated_assets (id) on delete set null,
  is_current boolean not null default false,
  locked_at timestamptz not null default timezone('utc', now()),
  locked_by uuid references auth.users (id) on delete set null,
  notes text
);

comment on table public.companion_character_sheet is
  'MED-09 the locked canonical description of Nori that every pose is judged '
  'against. One row may be current; older versions stay for the poses that '
  'were approved under them.';

-- One current sheet. Two would mean two answers to "is this the same Nori?".
create unique index if not exists companion_character_sheet_current_idx
  on public.companion_character_sheet (is_current)
  where is_current;

alter table public.companion_character_sheet enable row level security;

-- Readable by any signed-in user, because it is a description of a cartoon and
-- withholding it buys nothing; writable only by a platform admin, because
-- changing it silently changes what every future review means.
drop policy if exists companion_character_sheet_read on public.companion_character_sheet;
create policy companion_character_sheet_read
  on public.companion_character_sheet
  for select
  to authenticated
  using (true);

drop policy if exists companion_character_sheet_write on public.companion_character_sheet;
create policy companion_character_sheet_write
  on public.companion_character_sheet
  for all
  to authenticated
  using (nano_internal.is_platform_admin())
  with check (nano_internal.is_platform_admin());

-- ---------------------------------------------------------------------------
-- What a reviewer is handed
-- ---------------------------------------------------------------------------
create or replace function public.current_character_sheet()
returns table (
  version text,
  summary text,
  fixed_traits jsonb,
  variable_traits jsonb,
  rejection_triggers jsonb,
  reference_asset_id uuid,
  locked_at timestamptz
)
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select
    s.version,
    s.summary,
    s.fixed_traits,
    s.variable_traits,
    s.rejection_triggers,
    s.reference_asset_id,
    s.locked_at
  from public.companion_character_sheet s
  where s.is_current
  limit 1;
$$;

comment on function public.current_character_sheet() is
  'MED-09 the sheet a reviewer compares a pose against.';

revoke all on function public.current_character_sheet() from public, anon;
grant execute on function public.current_character_sheet() to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- v1
-- ---------------------------------------------------------------------------
insert into public.companion_character_sheet (
  version, summary, fixed_traits, variable_traits, rejection_triggers,
  reference_asset_id, is_current, notes
)
values (
  'v1',
  'Nori is a small soft floating creature: a single rounded egg or teardrop '
  'body in a purple-to-violet gradient, two short ear nubs leaning left, a '
  'large lighter lavender belly patch, two stubby arms, no legs, resting above '
  'a soft purple glow on a very dark navy background. Very large glossy dark '
  'eyes with white highlights carry the expression, and pink blush is always '
  'present. Soft airbrushed 2D, no outlines, no 3D render.',
  jsonb_build_array(
    'Egg or teardrop silhouette, widest at the bottom, slightly tilted',
    'Two short ear nubs on top, leaning to the character''s left',
    'Large lighter lavender oval belly patch on the lower front',
    'Two small stubby rounded arms, no legs',
    'Very large glossy dark eyes with one big white highlight each',
    'Soft pink blush ovals on both cheeks, always present',
    'Purple to violet body gradient on a very dark navy background',
    'Soft airbrushed shading, no hard outlines, no flat vector fills',
    'Square 1:1 framing, centred, generous margin for the circular mask'
  ),
  jsonb_build_array(
    'Arm position',
    'Mouth shape',
    'Eyebrow angle',
    'Eye shape: open, happy arcs, or glancing',
    'Body tilt and stretch',
    'Small sparkle accents, celebration only'
  ),
  jsonb_build_array(
    'A different silhouette: rounded rectangle, circle, animal, or humanoid',
    'Missing or relocated ear nubs, or a missing belly patch',
    'Added features: legs, feet, separate fingers, clothing, hats, props',
    'Hard outlines, flat vector fills, or a 3D render look',
    'A different palette, a light background, or a lost under-glow',
    'Eyes that are small, sharp, side-pupilled, or missing the highlight',
    'Text, letters, numbers, or UI in the frame',
    'Anything frightening, sad, crying, or scolding'
  ),
  (
    select id
    from public.generated_assets
    where slot = 'guide_greeting_staticArt'
      and kind = 'image'
      and moderation = 'approved'
    order by completed_at desc nulls last
    limit 1
  ),
  true,
  'MED-09. Written from the first companion image the owner approved. Mode '
  'never varies the art: Guide, Explorer, Quiz Coach, Builder, and Celebration '
  'are the same Nori wearing the ring and emblem the stage draws, which is why '
  'the bundled pack is one pose per mood rather than one per slot.'
)
on conflict (version) do update
set
  summary = excluded.summary,
  fixed_traits = excluded.fixed_traits,
  variable_traits = excluded.variable_traits,
  rejection_triggers = excluded.rejection_triggers,
  reference_asset_id = coalesce(
    excluded.reference_asset_id,
    public.companion_character_sheet.reference_asset_id
  ),
  notes = excluded.notes;
