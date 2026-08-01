# MED-12 — Nori Everywhere and Companion Coverage Gate

## Purpose

CMP-03 placed Nori on four student surfaces. Onboarding and quiz results built
their own throwaway runtimes, so cooldowns and the session budget stopped at
the edge of those screens. Nothing failed the build when a reaction had nowhere
to stand. Leaving the MED arc meant the avatar was about ninety percent done;
this module is the last ten of that ninety.

## Delivered

**One session companion, everywhere that matters.** Onboarding welcome and quiz
results (and quiz questions) now go through `CompanionSurfaceStage` and the
shared `CompanionController`. A celebration on results spends the same budget
that home does. A learner who finishes onboarding and lands on home is not
greeted twice in a row.

**Product surfaces mounted:** onboarding, home, learning (topic player), quiz
(questions + results), progress (empty recommendation). Game stays in the
placement policy but is deliberately not in the product mount set — GME-01 owns
that screen.

**Error, empty, and offline carry Nori without covering the button you need.**
`NanoViewStateHost` accepts an optional companion surface. The companion sits
above the chrome; the retry action stays exactly where it was. A test taps
"Try again" under a companion and asserts it fires.

**Coverage as a build gate.** `CompanionCoverage` derives the reachable
mode×mood matrix from the enums. Domain tests fail when a reachable reaction
cannot resolve a tier, when a mood has no caption, or when curated celebration
slots drift. Student tests fail when a product surface does not mount the
session companion.

**Moderation shows the gaps.** Above the review queue, a coverage report lists
celebration clip slots that have no approved art. An empty queue can no longer
hide an incomplete companion.

## Deliberately out of scope

- Game surface mount (GME-01)
- Level / achievement celebration hooks (XP-02, XP-03)
- Tier 3 personalised clips (feature-flagged, unbuilt)
