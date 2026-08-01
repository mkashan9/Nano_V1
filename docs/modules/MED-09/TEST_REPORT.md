# MED-09 test report

## Automated

| Suite | Result |
|-------|--------|
| `packages/nano_design_system` | 73 passed |
| `packages/nano_domain` | 235 passed |
| `packages/nano_media` | 43 passed |
| `apps/student_app` | 130 passed |
| `apps/admin_web` | 22 passed |
| `flutter analyze` (workspace) | 16 issues, all pre-existing, none in changed files |

## New tests

`packages/nano_design_system/test/nori_pose_pack_test.dart`

- Every mood in the enum has a bundled pose, and no two moods share one
  drawing. This is the build-time guard: a mood added later with no art behind
  it fails here rather than showing an icon to a child.
- Every declared pose is actually present in the package bundle and larger than
  1 KB, so a renamed or truncated file is caught rather than falling silently
  to the icon.
- The whole pack is under 256 KB. It is 135 KB today. Blowing the budget should
  mean compressing, not dropping a mood.
- The reachable matrix is still 25 pairs and every pair's mood has a pose. If
  someone adds a surface or an event, this test says so.

## Changed tests

`packages/nano_design_system/test/companion_art_test.dart`

The MED-08 ladder tests were rewritten for the new rung. Two assertions
inverted on purpose: "with nothing published the mood icon is the picture" is
now "the bundled pose is the picture", and a network failure now falls to the
pose rather than the icon. The icon assertions became `findsNothing`.

The helper also changed. `Image.network`'s frameBuilder renders the bundled
`Image` *inside* itself while the download is in flight, so both widgets are in
the tree and taking the first one tests nothing. The helper now collects
providers by type.

`apps/student_app/test/companion_reaction_test.dart`

Two tests asserted `Icons.celebration_rounded` and `Icons.refresh_rounded` as a
stand-in for "the right mood is showing", because the drawing did not exist.
They now assert the pose, which is what a child sees. The negative assertion —
a wrong answer must not show the celebration — was kept and strengthened for
the same reason.

## SQL

`supabase/tests/med09_pose_coverage.sql` — NOT RUN locally (no psql against the
development project from this machine). Reviewed by hand; it probes:

- exactly one current sheet exists
- it names a reference picture and that picture is an approved image
- a second current sheet is rejected by the partial unique index
- a platform admin can read the sheet through `current_character_sheet()`
- a learner may read the sheet and may not rewrite it

The migration itself was applied to the development project and verified:
`v1`, current, 9 fixed traits, 8 rejection triggers, reference resolved to the
approved `guide_greeting_staticArt` row.

## Not covered by automation

- Whether the six poses actually look like one character. No test can answer
  that; it is the whole content of the manual test.
- Whether the gentle retry pose reads as kind rather than sad. Same.
- Airplane mode. The fallback path is unit-tested with a refused network image,
  which is the same code path, but the real thing is worth seeing once.
