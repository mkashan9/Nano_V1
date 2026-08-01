# MED-11 — Full Narration and Celebration Clip Pack

## Purpose

MED-03 built narration and MED-06 cast the guide voice. One line had ever been
recorded. Nori could be seen everywhere and heard in exactly one place.

## Delivered

**Fifteen new recordings, sixteen in total.** Every published, non-personalised
line in the script book is now recorded in English and in Urdu, in the cast
`guide_educational` voice. Eight lines × two languages, minus the one that
already existed.

| Slug | English | Urdu |
|------|---------|------|
| `greeting-2` | approved (MED-06) | new |
| `idle-1` | new | new |
| `point-1` | new | new |
| `point-2` | new | new |
| `thinking-1` | new | new |
| `retry-1` | new | new |
| `celebration-1` | new | new |
| `celebration-2` | new | new |

`greeting-1` is deliberately absent. It says "Hello! {name} is here" and a
recording of a personalised line would say one child's companion name to every
other child. ADR-0008 makes those caption-only forever, and a test asserts that
no personalised line ever acquires an approved recording by accident.

**Total spend: 7,536 micros** — under a cent. The whole voice library costs
less than the two rejected json2video attempts from MED-06 did.

**Coverage as an invariant, not a fact.** Coverage is the kind of property that
is true the day it ships and quietly false six modules later. Both a SQL probe
and a domain test now fail if the script book grows a line nobody recorded, a
mood whose only line is personalised (permanently silent, invisible from
outside), or a recording from a superseded voice.

**Celebration source art queued.** The clip pack needs approved art to compose
from, and the celebration pose only existed bundled. It is now registered as a
curated asset and sits in the review queue beside the recordings.

## What is not finished

**The celebration clips are not rendered.** This is a gate, not an oversight.
A clip is composed from an *approved* image, and the celebration art is
unreviewed until you decide it. Rendering first would have meant bypassing the
MED-05 review gate, which is the one thing in this pipeline that must never be
convenient to skip.

Sequence is: approve the celebration art → clips are rendered from it → they
return to the same queue as video. Two of the five celebration clip slugs
(`celebration_celebration`, `quizCoach_celebration`) are already authored with
direction and motion; `guide`, `explorer`, and `builder` still need drafts.

## The Urdu question

Every Urdu line rendered without error, at a plausible size, at a plausible
cost. That is all a machine can tell you.

The cast voice is a Fish Audio reference clone selected against **English**
lines. Whether it reads Urdu script as Urdu, or as an English speaker guessing
at it, is a judgement only a listener can make, and it is the single most
important thing in the manual test.

Rejecting the Urdu set is a legitimate outcome and costs nothing: strict locale
match means a missing Urdu recording shows the caption, which is exactly what
Urdu learners have today.
