# CMP-01 — Nori Core Runtime

## Purpose

Give the companion one deterministic, local brain: a closed set of moments, six
core reactions, cooldowns that keep it from nagging, captions that survive a
muted device, and an asset ladder that never needs a network call. Nori becomes
something surfaces ask for guidance from, instead of each screen inventing its
own prose and art size.

## Deliverables

| Area | What shipped |
|------|--------------|
| Domain | `CompanionEvent`, `CompanionMood`, `CompanionAssetTier`, `CompanionScript`/`CompanionScriptBook`, `CompanionAssetManifest`, `CompanionReaction` |
| Domain | `CompanionRuntime` state machine and `CompanionPolicy` (junior/senior density) |
| Design system | `CompanionStage`, which renders a reaction inside the existing `CompanionSlot` |
| Student app | Quiz results react to the server outcome (Junior and Senior); component gallery shows every core reaction per experience |
| Tests | Domain runtime tests, design-system widget tests, student-app reaction tests |

## Rules

- Nori never calculates marks, score, XP, rank, or eligibility. A caller
  translates a server-authored outcome into an event
  (`CompanionEvent.forOutcome(passed: …)`) and passes it in.
- Reaction selection is deterministic: `notify` takes the clock and a seed as
  arguments, and script choice is `seed % lines`. No randomness, no wall clock,
  no network inside the runtime.
- Static approved art is the default. A clip tier only resolves when
  `clipsAvailable` is true, and otherwise falls back to a local tier.
- Junior guidance is prominent with an 8s cooldown; Senior is small, contextual,
  and stays silent on ordinary navigation (home, learning entry, per-question,
  idle).
- Essential moments (quiz complete, result, achievement, level up) ignore
  cooldowns.
- Classroom Mode and muted sound remove the voice but keep the caption; reduced
  motion (or Classroom Mode) forces static art.
- Cooldown history survives `dismiss()` and a preferences change, so dismissing
  a reaction cannot be used to re-trigger it.

## Out of scope

- Real companion art, animation files, and Aoede voice playback (MED-01)
- Generated clips, generation jobs, provenance, and budget (MED-02 / CMP-02)
- Server-side `companion_events` telemetry
- Companion on every listed surface; this module wires the results moment and
  the gallery, and leaves other screens on the plain `CompanionSlot`
