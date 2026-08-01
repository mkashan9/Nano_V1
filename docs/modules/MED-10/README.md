# MED-10 — Idle Life and Local Animation Tier

## Purpose

MED-09 gave Nori a drawing for every mood. A drawing that holds perfectly still
does not read as calm; it reads as broken. This module is the difference
between a picture of a character and a character.

## What was missing

`CompanionAssetManifest` has mapped the greeting mood to
`CompanionAssetTier.localAnimation` since CMP-01, and nothing implemented that
tier, so it silently resolved down to static art. Tier 1 of the handbook's
ladder — bundled, reusable, blink and bounce and subtle idle — existed only as
a name.

## Delivered

**A motion signature per mood.** `CompanionMotionSpec.forMood` gives each of the
six moods a breath period, a vertical bob, and a sway, chosen so the mood reads
with the sound off and the caption covered. Thinking sways widest, because on a
character whose head and body are one shape a slow tilt is the entire
vocabulary of pondering. Gentle retry is the only mood with no sway at all — a
waggle at a child who just got something wrong reads as being laughed at.

**`NoriLivingArt`,** which applies it. It draws nothing of its own, so it cannot
put Nori off model; the worst it can do is move her. It wraps whatever the art
ladder resolved, so a published picture and a bundled pose both breathe.

**Motion inside the mask.** The transform sits under the mode ring, the emblem,
and the play badge. The frame stays exactly still, so a learner aiming at the
play badge is not aiming at a moving target, and the ring reads as a frame
rather than as part of Nori.

## The three rules it holds to

**Accessibility decides, not the tier.** The gate is `NanoMotion.resolve`, the
one place reduced motion and Classroom Mode are read. A tier table cannot
outvote a child's setting, and the platform-level setting is honoured for a
learner who never visited our settings screen.

**Free when unseen.** The ticker comes from `SingleTickerProviderStateMixin`, so
Flutter's own `TickerMode` mutes it when the companion's route is not current,
and a backgrounded app produces no frames to drive it. Under reduced motion the
controller is stopped rather than merely ignored, so "still" also means "free".
There is no timer to leak.

**Nothing is fetched.** Every animation is arithmetic over art that already
shipped. No render spend, no network, nothing that can fail in a classroom with
bad wifi.

## Amplitudes

Nothing moves more than four percent, and most of it moves under two. On a
96-pixel circle that is under two pixels. A companion that moves enough to
notice is a companion competing with the lesson, and the automated tests fail
if a future edit pushes any channel past the ceiling.

## Out of scope

- **Eye blink.** See KNOWN_ISSUES; it needs a second eye state per pose and
  generated frames cannot be relied on to register pixel-for-pixel.
- Gesture animation — a wave that actually waves. That is a clip, and clips are
  MED-11.
- Motion on anything but the companion.
