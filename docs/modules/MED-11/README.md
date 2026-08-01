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

**The celebration clip pack, all five modes.** `guide`, `explorer`,
`quizCoach`, `builder`, and `celebration` each have a rendered clip, composed
from the approved celebration art by Wan, silent, three to four seconds, at
**zero cost**.

The clips were held back until the source art was approved, because a clip
composes from an *approved* image and rendering first would have meant
bypassing the MED-05 gate. The owner approved the art and the pack followed in
the same session.

Three of the five reactions did not exist in the clip library.
`create_reaction_clip_draft` authors a new version of an *existing* reaction and
refuses an unknown slug, so `guide`, `explorer`, and `builder` arrive by
migration rather than over the wire. That constraint is worth keeping: a
reaction is a product decision that belongs in git and in review, not something
a script can conjure at 2am.

## The Urdu question, and how it was settled

Every Urdu line rendered without error, at a plausible size and cost. That is
all a machine can tell you. The cast voice is a Fish Audio reference clone
selected against **English** lines, and nothing about Urdu was part of that
choice.

The owner was shown this and chose to approve the set without listening. The
review note on all sixteen assets records that, so if the Urdu turns out wrong
the reason is in the log rather than in somebody's memory. Rejecting them later
costs nothing: strict locale match degrades a missing recording to its caption.

## One clip was rendered twice

`guide_celebration` first came back from `json2video_compose` — the fallback
fired because the Wan attempt was still generating when the request was
retried. It was rejected and re-rendered on Wan.

That mattered more than one clip usually would. Guide is the default mode, so
it is the celebration most learners actually reach, and json2video is the
provider whose output the owner rejected twice in MED-06 for looking fake. It
also costs 15,000 micros against Wan's zero. The whole pack would have been
free and consistent except for the one clip nobody would have thought to check.

There is now a probe that fails if any approved clip came from the fallback.
