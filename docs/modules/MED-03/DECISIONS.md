# MED-03 decisions

## Aoede through a registry, not a hard-coded string

A request names `aoede` (or takes the default). The Edge Function looks up
`provider_voice_name` from `narration_voices`. Swapping providers later is a row
change, not a client change, and a caller can never invent a voice the database
does not know.

## Authored lines, not free-form prompts for speech

Speech uses the published wording of a `narration_line_version`. Free-form prompts
remain available through `request_generated_asset` for other media; narration for
the Guide is curated so the audio cannot drift from the caption the app shows.

## Placeholders are caption-only

`greeting-1` contains `{name}`. Recording it once would say one child's companion
name to every other child. The database refuses with `NM007`; the client treats
personalised lines as never playable. The caption still substitutes the name.

## Strict locale, no cross-language audio

English audio under an Urdu UI is worse than silence. `list_narration_lines` and
`NarrationCatalog` are per-locale. Switching language clears the narration cache.

## Aspect ratio is ignored for voice in the hash

A recording has no shape. Callers still pass a harmless default for the shared
RPC signature; the hash treats it as empty for `voice` so two callers cannot pay
twice for the same audio by disagreeing on `1:1` vs `16:9`.

## User-triggered playback only

MED-01 owns audio-focus rules for when real media plays. This module never
autoplays. The Listen control appears only when a recording exists, a player is
attached, sound is allowed, and the wording matches. Today no player is attached
in the student app, so the control never appears — which is the correct resting
state until a real plugin and an approved recording both exist.

## Player as a seam

`NanoVoicePlayer` / `NanoRecordingVoicePlayer` let wiring and tests land before
choosing a Flutter audio plugin. With no player, captions are complete.
