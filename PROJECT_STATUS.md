# PROJECT_STATUS

## Current state

- **Current release:** R4 Companion
- **Current module:** MED-08 Real Playback and Companion Art Rendering
- **Current status:** ACTIVE
- **Current branch:** module/MED-08-playback-and-companion-art
- **Last completed module:** MED-07
- **Application name:** Nano

## Releases

- R1 Identity: complete
- R2 Student Core: complete (STU-03 through STU-05 DONE)
- R3 Learning: complete (LRN-01–LRN-05, QZ-01–QZ-06 DONE)
- R4 Companion: CMP-01–CMP-03 and MED-01–MED-07 DONE; MED-08 through MED-12
  are the avatar arc that makes the companion real in the app

## The avatar arc

MED-01 through MED-07 built a complete pipeline — generate, budget, review,
publish, deliver — and none of it reaches a child. These five modules close
that gap and end with the companion roughly ninety percent implemented.

| Module | What it delivers | Status |
|--------|------------------|--------|
| MED-08 | The app can finally show an image and play a voice or a clip | ACTIVE |
| MED-09 | One canonical Nori, static art for all 25 reachable reactions, bundled offline floor | BACKLOG |
| MED-10 | Free local motion: breathing, blink, a bounce that reads as the mood | BACKLOG |
| MED-11 | A recorded line for every moment, a clip for every celebration | BACKLOG |
| MED-12 | Presence on every surface, plus a build gate that fails when a reaction has no art | BACKLOG |

The remaining tenth is deliberately deferred: the game surface waits on
GME-01, level and achievement celebrations wait on XP-02 and XP-03, and Tier 3
personalised clips stay feature-flagged and unbuilt.

## What a learner can actually see and hear

Still nothing generated reaches a child. Nori is a Material `pets` icon in a
coloured circle; the repository contains no art files and no `assets:` block,
no pubspec declares an audio or video plugin, and both player seams are null
in `main.dart`, so Listen and Play never render. MED-08 is the correction.

## Content coverage

| Surface | Authored | Approved |
|---------|----------|----------|
| Narration lines | 6 slugs × en/ur | 2 (`greeting-2` en, guide voice) |
| Reaction clips | 3 slugs | 1 (`guide_greeting` Wan clip) |
| Companion art | 1 slot | 1 (`guide_greeting` 1:1) |
| Reachable reactions needing art | 25 | 1 |

## Owner decision waiting

None. MED-07 was approved and merged. MED-08 is in progress and will return
for a manual test.
