# MED-06 — Fish Audio Narration and Composed Reaction Clips

## Purpose

MED-03 named Gemini's Aoede as the Learning Guide's voice. MED-04 named Veo as
the clip provider. Neither ever ran: no key was set, every recording and every
clip failed closed, and every companion surface kept its local art. The owner
then chose different providers — Fish Audio for voice, json2video for video —
and asked that the switch wait for MED-05. MED-06 is that switch.

The video change is not a config change. Veo invented footage from a description.
json2video is a compositor: it is handed a picture and returns that picture
moving. A clip can no longer show anything a reviewer has not approved, because
the only picture it can animate is one that already passed MED-05.

## Deliverables

| Area | What shipped |
|------|--------------|
| Database | `fish_audio_voice` and `json2video_compose` provider rows; Gemini defaults disabled, not deleted |
| Database | `composes_from_art` on `generation_providers` — the flag `request_reaction_clip` reads |
| Database | `guide_fish_stock` narration voice (`provider_voice_name = 'stock'`); `aoede` disabled |
| Database | `motion` on `reaction_clip_versions` — closed set: `hold`, `settle`, `driftIn`, `pushIn`, `dip` |
| Database | `nano_internal.approved_companion_art` — ready + approved + matching shape, or nothing |
| Database | `request_reaction_clip` refuses with `NM011` before a composing ask costs anything |
| Database | `reaction_clip_composition` — worker-only movie plan; never returns unapproved art |
| Edge | `FishAudioVoiceAdapter` — MP3 via `/v1/tts`, stock voice until a `reference_id` is picked |
| Edge | `Json2VideoComposeAdapter` — Ken Burns motion over a signed URL of approved art |
| Edge | `generate-asset` redeployed (version 3) with the compose path and `NM011` mapping |
| Dart | Fake repository defaults mirror the new provider ids |
| Tests | Adversarial SQL on `nano_v1`; 56 Deno adapter tests (including MED-03/04 for the first time) |

## Rules

- **Keys never leave the Edge Function.** They are secrets, not `dart-define`s,
  not git, not log lines. A missing key is `PROVIDER_UNCONFIGURED`.
- **Unapproved art is never composed.** The database refuses before the day's
  budget is spent, and the worker's plan function refuses again independently.
- **Motion is a closed set.** A curator cannot author a movement the compositor
  cannot render, and a published motion cannot be edited in place (`NM008`).
- **Shape still matters.** Approved square art does not license a tall clip
  (`NM011`); an unauthored shape is still `NM009`.
- **Gemini stays deployed.** Switching a provider row back does not need a
  redeploy; the adapters remain registered under their own ids.
- **Budgets still bite.** A spent video ceiling refuses with `NM006` before any
  compositor is reached.

## Out of scope

- Picking a specific Fish `reference_id` — the stock voice is intentional until
  the owner chooses one (a new narration_voices row, not an edit)
- Correcting `VIDEO_COST_MICROS_PER_CLIP` against a real invoice
- Audio / video playback in the reviewer's browser (still no plugin)
- Learner-facing published media end to end — that still needs MED-05 approve on
  whatever this module produces

## Provenance

- Voice authoring and reuse hash: MED-03
- Async clip jobs and recoverable claims: MED-04
- Approval as the only publication: MED-05
- Daily budgets: MED-02
- Owner provider decisions: locked in `automation/modules/MED-06.yaml`
