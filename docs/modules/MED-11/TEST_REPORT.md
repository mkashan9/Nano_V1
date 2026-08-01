# MED-11 test report

## Automated

| Suite | Result |
|-------|--------|
| `packages/nano_media` | 48 passed |
| `packages/nano_data` | 112 passed |
| `packages/nano_domain` | 235 passed |

## New tests

`packages/nano_media/test/narration_coverage_test.dart` — five assertions, all
derived from the enums rather than from a list, so adding an event or a mood is
enough to make them fail.

- Every reachable mood has at least one line.
- Every reachable mood has at least one line that *can be recorded*. This is
  the non-obvious one: a mood whose only line is personalised is permanently
  silent under ADR-0008, however much narration gets generated, and nothing
  about it looks broken from outside.
- No line has an empty Urdu string, which would render as English words under
  an Urdu caption.
- A line is personalised in both languages or neither. Half-personalised is the
  worst case — recordable in one language only, so a child hears English and
  reads Urdu.
- The recordable slug set is exactly the eight the generation run covered. A
  deliberate tripwire: when the script book changes this fails with "narration
  needs regenerating" rather than leaving a silent gap.

## SQL

`supabase/tests/med11_narration_coverage.sql` — NOT RUN locally (no psql to the
development project from this machine). Reviewed by hand; it probes:

- every published non-personalised line has a non-rejected recording in `en`
  and `ur`
- no personalised line has an approved recording
- every recording comes from the currently cast provider, so a superseded voice
  cannot linger
- no storage object is shared across two locales, which is strict locale match
  checked from the database side
- a learner sees nothing that is not approved
- reports total voice spend

## Live generation

Run against the development project as `platform@nano.dev`.

| | |
|---|---|
| Recordings requested | 16 |
| Newly rendered | 15 |
| Reused | 1 (`greeting-2` en, already approved) |
| Failures | 0 |
| Total voice spend | 7,536 micros |
| Moderation state | all new rows `unreviewed` |

Curated art registered: `celebration_celebration_staticArt`, 27,099 bytes,
`unreviewed`, provenance recording that it is the MED-09 bundled pose generated
against character sheet v1.

## Not covered by automation, and not coverable

**Whether the Urdu recordings are Urdu.** Every one rendered at a plausible
size and cost. No test can hear them. The cast voice is a reference clone
selected against English lines and was never verified for Urdu script; this is
the central question of the manual test and rejecting all eight is a supported
outcome.

**Whether `retry-1` sounds patient rather than disappointed.** Same class of
problem, and it matters because that line plays to a child who just got
something wrong.

## Deliberately incomplete

The celebration clips are not rendered. A clip composes from an *approved*
image and the celebration art is unreviewed until the owner decides it.
Rendering first would mean bypassing the MED-05 gate. See DECISIONS.
