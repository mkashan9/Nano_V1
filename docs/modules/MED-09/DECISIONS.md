# MED-09 decisions

## One drawing per mood, not one per slot

The module was specified as static art for all 25 reachable mode-and-mood
pairs. It ships six drawings.

A slot is `mode_mood_tier`. CMP-02 defines a mode as the same character with a
different accent and framing, and `CompanionStage` already draws both: the mode
ring and the mode emblem sit around the art, outside it. So Guide Nori pointing
and Explorer Nori pointing differ in the ring, not in the character — and if
they were separate generated files they would differ in the character too,
slightly, in the way generated sets always do.

Six files is therefore not a reduced version of twenty-five. It is the version
where the four modes cannot drift apart, because they are the same bytes.

The per-slot path is untouched: the catalog still prefers published art for the
exact slot, so a curator who wants a genuinely different Quiz Coach pose
approves one and gets it.

## The sheet is a row as well as a document

`docs/companion/NORI_CHARACTER_SHEET.md` is where an engineer reads it.
`companion_character_sheet` is where a reviewer reads it — in admin_web, beside
the pose they are deciding on, which is the only moment the sheet has a job.

Duplication is the cost and it is the right trade. A sheet nobody can see while
reviewing is a sheet nobody uses, and the failure it exists to prevent is not
one an engineer catches in a diff. It is one a reviewer catches six weeks later
when the ears have quietly migrated.

Versioned, with one current row, because a pose approved under v1 was approved
against v1. Changing the definition silently changes what every past approval
meant.

## Bundled with the design system, not with the app

The assets are declared in `nano_design_system/pubspec.yaml` and loaded with
`package: 'nano_design_system'`. Any app that draws the companion gets the same
character without repeating an `assets:` block, and there is no way for
student_app and a future teacher-facing preview to ship different Noris.

admin_web pays 135 KB for art it does not draw. That is the price of the
guarantee and it is cheap.

## JPEG on an opaque background, not PNG with alpha

The approved reference has a solid dark navy background and the owner approved
it that way, so the pack matches it: published and bundled art read the same
inside the circular mask.

JPEG at quality 90 costs 135 KB for the set where PNG cost 1.9 MB. Alpha would
have been nicer for a future surface that wants Nori over arbitrary content,
and nothing today wants that. MED-10 can revisit when motion arrives.

## The icon stays in the code

`_icon` is still the last rung, reachable only if a bundled asset fails to
decode — a corrupt install. Keeping it costs nothing and removing it would mean
a blank frame in the one case where a blank frame is worst.

## Reference conditioning, not prompt discipline

Every pose was generated with the approved `guide_greeting_staticArt` image as
a reference input, not merely with a careful text prompt. The earlier attempt
to hold a character with words alone is what produced the art the owner
rejected in MED-06. The owner's locked decision for this module says reference
conditioning is mandatory, and the sheet's `reference_asset_id` records which
picture every pose was conditioned on.
