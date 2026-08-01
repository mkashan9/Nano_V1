# XP-06 decisions

## Privacy-safe first name

Share cards use the first whitespace token of `display_name` only. Full
school-linked names, email, guardian, attendance, marks, class, and school
never appear on the card payload.

## Featured pins

Max three. `set_featured_achievements` replaces the set atomically and
requires each id to be an `achievement_awards` row owned by `auth.uid()`.
Clients cannot insert into `featured_achievements` directly.

## Clipboard before images

This module ships clipboard share text. Image generation and external share
targets stay with SOC-01 / SOC-04 so XP-06 can land without media pipelines.

## Owner share vs public projection

`show_achievements` still controls the public projection. Clipboard share is
an explicit owner action and remains available when the public toggle is off.
