# PROJECT_STATUS

## Current state

- **Current release:** R4 Companion
- **Current module:** MED-09 Nori Character Sheet and Static Pose Pack
- **Current status:** USER_TEST
- **Current branch:** module/MED-09-character-sheet-and-poses
- **Last completed module:** MED-08
- **Application name:** Nano

## Releases

- R1 Identity: complete
- R2 Student Core: complete (STU-03 through STU-05 DONE)
- R3 Learning: complete (LRN-01–LRN-05, QZ-01–QZ-06 DONE)
- R4 Companion: CMP-01–CMP-03 and MED-01–MED-08 DONE; MED-09 through MED-12
  are the rest of the avatar arc

## The avatar arc

MED-01 through MED-07 built a complete pipeline — generate, budget, review,
publish, deliver — and none of it reaches a child. These five modules close
that gap and end with the companion roughly ninety percent implemented.

| Module | What it delivers | Status |
|--------|------------------|--------|
| MED-08 | The app can finally show an image and play a voice or a clip | DONE |
| MED-09 | One canonical Nori, static art for all 25 reachable reactions, bundled offline floor | USER_TEST |
| MED-10 | Free local motion: breathing, blink, a bounce that reads as the mood | BACKLOG |
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

Still missing: motion. Every pose holds perfectly still until the reaction
changes. That is MED-10.

## Content coverage

| Surface | Authored | Approved |
|---------|----------|----------|
| Narration lines | 6 slugs × en/ur | 2 (`greeting-2` en, guide voice) |
| Reaction clips | 3 slugs | 1 (`guide_greeting` Wan clip) |
| Companion art, published per slot | 1 slot | 1 (`guide_greeting` 1:1) |
| Companion art, bundled per mood | 6 moods | 6 (ships with the app) |
| Reachable reactions with a drawing | 25 | 25 |

## Owner decision waiting

Run the MED-09 manual test in `docs/modules/MED-09/MANUAL_TEST.md`. The real
question is the character sheet: everything generated from here is judged
against the version you lock now.
