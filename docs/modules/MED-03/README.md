# MED-03 — Voice Generation and Aoede Learning Guide

## Purpose

Give the Learning Guide a real voice without making speech a requirement. Every
companion line stays a caption first. A recording is an optional enhancement that
says exactly those words, in that language, in one registered voice (Aoede). When
no recording exists, no player is wired, sound is off, or Classroom Mode is on,
the learner still has every word on screen and nothing is offered to play.

## Deliverables

| Area | What shipped |
|------|--------------|
| Database | `narration_voices` registry (default: Aoede via `gemini_voice_aoede`) |
| Database | `narration_lines` + `narration_line_versions` — QZ-01-style draft/published/retired, bilingual columns, immutable published wording |
| Database | `generated_assets.voice_id` and a voice-aware hash (voice identity in, aspect ratio out for audio) |
| Database | `request_narration_line`, `list_narration_lines`, `create_narration_line_draft`, `publish_narration_line_version` |
| Database | Nine companion lines seeded to match `CompanionScriptBook` (greeting-1 is caption-only: it names the companion) |
| Edge Function | Real `GeminiVoiceAdapter`: Gemini TTS → PCM → WAV, Aoede voice, `en-US` / `ur-PK` |
| Edge Function | `generate-asset` accepts `narration_slug` and resolves the provider voice name from the registry |
| Domain | `NarrationLine`, `NarrationAudio`, `NarrationNotRecordable`; `CompanionScript.isPersonalised` |
| nano_media | `NarrationCatalog` (strict locale, wording match, personalised/sound-off fallbacks) and `NarrationCache` |
| Data | `NarrationRepository` with fake and Supabase implementations |
| Design system | `NanoVoicePlayer` seam, Listen control on `CompanionStage`, wired through `CompanionController` |
| Student app | Catalog loaded per locale, cleared on sign-out; no player attached yet, so no Listen control appears |
| Tests | Adversarial SQL on `nano_v1`, Dart unit/widget coverage |

## Rules

- **One registered voice.** A request names a voice from `narration_voices` or
  takes the default. It never names a provider voice string.
- **Captions are the product.** Audio is optional. Missing audio is not an error.
- **Audio says what the caption says.** Wording mismatch, personalised placeholders,
  and language mismatch all refuse playback rather than approximate.
- **Nothing speaks unasked.** A learner taps Listen. Muted and Classroom Mode
  learners are offered no control.
- **Reuse is free.** Same line + language + voice = one recording, charged once
  under the MED-02 budgets.
- **The key stays on the server.** `VOICE_PROVIDER_API_KEY` exists only in the
  Edge Function environment.

## Out of scope

- Real Flutter audio plugin (the `NanoVoicePlayer` seam is ready; no plugin yet)
- Curator UI for authoring narration (RPCs exist; admin screens are later)
- Deploying `generate-asset` or setting the voice provider key (owner approval)
- Video generation (MED-04) and asset review UI (MED-05)

## Provenance

- Versioning pattern: QZ-01 question bank
- Budget and reuse: MED-02
- Companion script IDs and captions: CMP-01 `CompanionScriptBook`
- Voice choice: handbook Learning Guide / Aoede
