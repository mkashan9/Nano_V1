-- MED-11: the rest of the celebration clip library.
--
-- MED-04 seeded three reactions and MED-06 made the library closed on purpose:
-- create_reaction_clip_draft authors a new *version* of an existing reaction
-- and refuses an unknown slug, so a clip cannot be invented from an RPC call.
-- That is the right shape — a reaction is a product decision that belongs in
-- git and in review, not something a script can conjure — and it means the
-- three missing celebration modes arrive here rather than over the wire.
--
-- CompanionAssetManifest promotes only the celebration mood to shortClip, so
-- with guide, explorer, and builder added the celebration tier is complete and
-- the library is closed again.

insert into public.reaction_clips (slug, mode, mood, notes)
values
  ('guide_celebration', 'guide', 'celebration',
   'The guide is the default mode, so this is the celebration most learners '
   'actually reach. Warm rather than loud.'),
  ('explorer_celebration', 'explorer', 'celebration',
   'Finishing something that was explored rather than drilled. Reads as '
   'discovery.'),
  ('builder_celebration', 'builder', 'celebration',
   'Finishing something that was made. Reads as completion rather than as a '
   'correct answer.')
on conflict (slug) do nothing;

-- Direction differs per mode even though the source drawing does not. CMP-02
-- settled that the mode changes the framing and the accent rather than the
-- character, and the same holds in motion: it is one companion celebrating
-- four different kinds of achievement, not four companions.
--
-- Every direction is capped at three seconds and says "calm and unhurried".
-- A celebration a child sees several times a day is a thing they will learn to
-- sit through, so the ceiling matters more than the flourish.
insert into public.reaction_clip_versions
  (clip_id, version, status, direction, aspect_ratios, duration_seconds,
   direction_hash, motion, published_at)
select
  rc.id,
  1,
  'published',
  seed.direction,
  seed.aspect_ratios,
  seed.duration_seconds,
  nano_internal.reaction_clip_hash(seed.direction, seed.duration_seconds),
  seed.motion,
  timezone('utc', now())
from (
  values
    ('guide_celebration',
     'A small round friendly companion with soft rounded edges gives a warm '
     'approving nod and a small clap, a few soft sparkles rising and fading, '
     'warm daylight palette, calm and unhurried, plain uncluttered background, '
     'no text, no people, loopable.',
     array['1:1'],
     3,
     'settle'),
    ('explorer_celebration',
     'A small round friendly companion with soft rounded edges bounces once '
     'with both arms raised, small sparkles drifting upward as if something '
     'has just been found, warm daylight palette, calm and unhurried, plain '
     'uncluttered background, no text, no people, loopable.',
     array['1:1'],
     3,
     'pushIn'),
    ('builder_celebration',
     'A small round friendly companion with soft rounded edges holds both arms '
     'up in a proud steady finish, a few slow sparkles settling around it, '
     'warm daylight palette, calm and unhurried, plain uncluttered background, '
     'no text, no people, loopable.',
     array['1:1'],
     3,
     'dip')
) as seed(slug, direction, aspect_ratios, duration_seconds, motion)
join public.reaction_clips rc on rc.slug = seed.slug
where not exists (
  select 1 from public.reaction_clip_versions v where v.clip_id = rc.id
);
