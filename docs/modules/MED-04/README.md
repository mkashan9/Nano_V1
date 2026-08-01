# MED-04 — Video Generation and Reusable Reaction Library

## Purpose

Author a companion reaction once, generate a short silent clip for it, and let
every surface that reaches that reaction reuse it. Clips stay optional against
local art: reduced motion, a missing approval, a missing player, and a network
failure all look the same — the icon the app already ships.

## Deliverables

| Area | What shipped |
|------|--------------|
| Database | `reaction_clips` + `reaction_clip_versions` — stable `<mode>_<mood>` slug, immutable published direction, authored shapes |
| Database | Claim expiry, `provider_job_id`, `poll_after`; abandoned jobs return to the queue; exhausted jobs fail instead of blocking forever |
| Database | `request_reaction_clip`, `list_reaction_clips`, progress + pending-job RPCs |
| Database | Three seeded reactions (`celebration_celebration`, `guide_greeting`, `quizCoach_celebration`); Veo as default video provider |
| Edge Function | Real async `GeminiVeoAdapter`; `clip_slug` path that starts or resumes a long job and returns `{pending:true}` until bytes exist |
| Domain | `ReactionClip`, per-slot `clipSlots` on the runtime (boolean `clipsAvailable` kept) |
| Design system | `NanoClipPlayer` seam; play badge on companion art when a clip exists; user-triggered only |
| Student app | `setClipSlots` + `attachClips`; no player attached yet, so local art remains the resting state |
| Tests | Adversarial SQL on `nano_v1`, Dart unit/widget coverage |

## Rules

- **One authored reaction, many surfaces.** The slug is `<mode>_<mood>`, matching
  `CompanionReaction.assetKey` without the tier suffix.
- **Clips are silent and language-neutral.** Stored under `en`; English fallback
  hands them to Urdu learners unchanged.
- **Availability is per slot.** Authoring a greeting clip does not promise
  celebration clips.
- **A long job must not poison reuse.** Expired claims are released; exhausted
  claims fail; live claims are left alone.
- **Nothing autoplays.** A learner taps to play. Reduced motion is offered
  nothing.
- **The key stays on the server.**

## Out of scope

- Real Flutter video plugin (seam is ready; no `video_player` dependency)
- Curator UI for authoring clips (RPCs exist; MED-05 owns review UI)
- Deploying `generate-asset` or setting `VIDEO_PROVIDER_API_KEY`
- Asset moderation UI (MED-05)

## Provenance

- Versioning pattern: MED-03 narration lines / QZ-01
- Budgets and reuse: MED-02
- Slot contract: CMP-01/02 `CompanionReaction.assetKey`
- Async claim recovery: forced by real video providers (Veo)
