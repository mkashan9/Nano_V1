# ADR-0008: The Learning Guide's voice is a female teacher, not the mascot

## Status

Accepted (owner, 2026-08-01). Cast as Fish Educational Guide
(`reference_id = 2c408095b1294de896376eff6a638d90`, registry id
`guide_educational`) on the same day.

## Context

Handbook §9 and §10.1 call for an "Aoede Learning Guide voice" as part of Nori's
one approved identity, but never say whose voice it is or what it should sound
like. "Aoede" was the name of a Gemini TTS preset; MED-06 replaced Gemini with
Fish Audio, so the word no longer names anything Nano can order.

Two readings of the guide voice were both live in the code, and they lead to
different recordings. Either Nori is speaking — in which case the voice should
be small, playful, and character-like, and lip-sync eventually matters — or the
voice is a guide narrating over the scene, in which case it should sound like a
teacher and Nori's mouth is irrelevant.

Nothing recorded which reading was correct, and the default that shipped was
whatever Fish's stock voice happened to be.

## Decision

The guide voice belongs to the companion as its guiding narration, and it reads
as a **teacher speaking alongside the learner** rather than a cartoon character
performing. It is:

- **Female.**
- **Warm, clear, and measured** — a teacher's register, not an announcer's and
  not a character's.
- **Background guidance.** It supports what the learner is doing; it never
  performs, never dominates, and never becomes the thing being watched.

Consequences of that reading, which is why the reading is worth recording:

- Lip-sync is not a requirement, now or later. A guide voice narrating over a
  scene does not need the mascot's mouth to agree with it.
- Reaction clips stay **silent** (MED-04). Motion and voice are separate tracks
  precisely because the voice is not coming out of the character.
- Voice casting is judged on warmth and clarity for a child, not on character
  fit.

The stock Fish voice is not the decision. It is what plays until a
`reference_id` is chosen, and it was never cast for this.

## Consequences

`narration_voices` gains a row for the chosen voice rather than an edit of
`guide_fish_stock`, because the voice id is part of the reuse hash (MED-03) and
editing in place would silently keep every recording made in the old voice.

Existing recordings made in the stock voice are superseded rather than migrated:
they were never approved for a learner, so nothing published changes.

Handbook wording that says "Aoede" should be read as "the Learning Guide voice".
The handbook is extracted from the owner's DOCX and is not edited here; this ADR
carries the fact until the handbook is regenerated.
