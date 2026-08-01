# MED-09 — Nori Character Sheet and Static Pose Pack

## Purpose

MED-08 gave the app the ability to show a picture. This module gives it a
picture worth showing, on every surface, with no network and nobody's approval
required.

## What was missing

One approved image existed: `guide_greeting_staticArt`. Everywhere else — 24
other reachable reactions — Nori was a Material `pets`, `waving_hand`,
`celebration`, or `refresh` icon in a coloured circle. Reduced motion collapses
every tier down to static art, so static art is the floor under the entire
companion system, and the floor was a placeholder.

## Delivered

**A canonical character sheet, recorded twice.** `docs/companion/NORI_CHARACTER_SHEET.md`
for the repository and a `companion_character_sheet` row for the reviewer, who
cannot read the repository while working in admin_web. It is versioned, it
names the approved picture it was written from, and exactly one version may be
current — two would mean two answers to "is this the same Nori?".

**A bundled pose for every mood.** Six drawings in
`packages/nano_design_system/assets/companion/`, 512×512 JPEG, 135 KB for the
set. Each one was generated conditioned on the reference image the owner
already approved, so the pack is a family rather than six strangers.

**The rung beneath published art.** `_CompanionArt` now falls clip → published
picture → bundled pose → icon. The bundled rung needs no network, no session,
and no approval, which is what makes the icon unreachable in practice: the only
way to reach it is a corrupt bundle.

## The decision worth arguing with

The reachable matrix is 25 mode-and-mood pairs and the pack has six files.

CMP-02 defines a mode as the same character wearing a different accent and
framing — never a different character — and the stage already draws the mode
ring and the mode emblem around the art. So one drawing per mood renders all 25
pairs correctly, and no two modes can drift apart, because they are the same
file.

Twenty-five near-identical generated images would have bought nothing and cost
the one thing this module exists to protect. Character drift is the known
failure of generating a mascot one pose at a time; generating four variants of
each pose multiplies the chance of it by four.

Published per-slot art still wins. A curator who genuinely wants Quiz Coach
Nori drawn differently approves art for that exact slot and the catalog prefers
it. This is the floor, not the ceiling.

## Rules kept

- Art is language neutral: one pose serves English and Urdu
- Junior and Senior resolve every pose their placement policy can reach
- Nothing bypasses review: curated art still enters `unreviewed`
- The sheet is readable by any signed-in user, writable only by a platform admin

## Out of scope

- Motion. The poses are still. Breathing, blink, and mood bounce are MED-10.
- Per-slot published art for the other 24 slots. The path is open and the floor
  no longer depends on it.
- Transparency. The poses carry the same dark navy background as the approved
  reference, so the circle reads consistently with published art.
