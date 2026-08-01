# PROJECT_STATUS

## Current state

- **Current release:** R4 Companion
- **Current module:** MED-10 Idle Life and Local Animation Tier
- **Current status:** USER_TEST
- **Current branch:** module/MED-10-idle-life-and-local-animation
- **Last completed module:** MED-09
- **Application name:** Nano

## Releases

- R1 Identity: complete
- R2 Student Core: complete (STU-03 through STU-05 DONE)
- R3 Learning: complete (LRN-01–LRN-05, QZ-01–QZ-06 DONE)
- R4 Companion: CMP-01–CMP-03 and MED-01–MED-09 DONE; MED-10 through MED-12
  are the rest of the avatar arc

## The avatar arc

MED-01 through MED-07 built a complete pipeline — generate, budget, review,
publish, deliver — and none of it reaches a child. These five modules close
that gap and end with the companion roughly ninety percent implemented.

| Module | What it delivers | Status |
|--------|------------------|--------|
| MED-08 | The app can finally show an image and play a voice or a clip | DONE |
| MED-09 | One canonical Nori, static art for all 25 reachable reactions, bundled offline floor | DONE |
| MED-10 | Free local motion: breathing, drift, a tilt that reads as the mood | USER_TEST |
| MED-11 | A recorded line for every moment, a clip for every celebration | BACKLOG |
| MED-12 | Presence on every surface, plus a build gate that fails when a reaction has no art | BACKLOG |

The remaining tenth is deliberately deferred: the game surface waits on
GME-01, level and achievement celebrations wait on XP-02 and XP-03, and Tier 3
personalised clips stay feature-flagged and unbuilt.

## What a learner can actually see and hear

Nori is a drawing everywhere now, in the mood the moment calls for. On the
Junior home she is the approved published art, with a Listen button in the cast
guide voice and a play badge for the Wan clip. Everywhere else she is the
bundled pose for that mood, which needs no network and no approval. The mood
icon is no longer reachable outside a corrupt install.

She now breathes, drifts, and tilts, differently for each mood, and stops dead
the moment a learner asks for reduced motion or Classroom Mode. All of it is
arithmetic over art that already shipped: no render spend, no network, and no
ticker running while nobody is looking.

Still missing: gesture. Nori's pointing pose points because it was drawn
pointing, not because an arm moves. Real gesture is a clip, and the clip pack
is MED-11.

## Content coverage

| Surface | Authored | Approved |
|---------|----------|----------|
| Narration lines | 6 slugs × en/ur | 2 (`greeting-2` en, guide voice) |
| Reaction clips | 3 slugs | 1 (`guide_greeting` Wan clip) |
| Companion art, published per slot | 1 slot | 1 (`guide_greeting` 1:1) |
| Companion art, bundled per mood | 6 moods | 6 (ships with the app) |
| Reachable reactions with a drawing | 25 | 25 |

## Owner decision waiting

Run the MED-10 manual test in `docs/modules/MED-10/MANUAL_TEST.md`. It is
judged by sitting still and watching rather than by clicking: the two failure
modes are "looks frozen" and "will not stop fidgeting", and both take a minute
of doing nothing to notice.
