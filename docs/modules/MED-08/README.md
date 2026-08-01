# MED-08 — Real Playback and Companion Art Rendering

## Purpose

Seven media modules built a pipeline that generates, budgets, reviews,
publishes, and delivers companion assets. None of it reached a child. This
module is the last mile: the app can now show an approved picture, play an
approved narration line, and play an approved reaction clip.

## What was actually missing

Worth stating plainly, because the gap was larger than the module list
suggested:

- Nori was drawn as `Icons.pets_rounded` inside a coloured circle. There was no
  code path in `CompanionStage` that could display an image, so publishing art
  would have changed nothing on screen.
- No `pubspec.yaml` in the repository declared an audio or video plugin.
- `NanoVoicePlayer` and `NanoClipPlayer` were interfaces with only recording
  doubles behind them, and `main.dart` passed neither, so `Listen` and
  `Play clip` could never render.
- `CompanionAssetCatalog.choose` resolved clips only. A published *image* was
  never looked up at all.
- `CompanionAssetManifest.resolve` could drop a tier but never raise one, so the
  approved Wan greeting clip was unreachable: greeting's declared tier is
  `localAnimation`, and only a mood already declared `shortClip` could become
  one.

## Deliverables

- `NanoAudioVoicePlayer` (just_audio) and `NanoVideoClipPlayer` (video_player),
  both in `apps/student_app/lib/app/playback/`, wired in `main`.
- Both player seams became `Listenable`; the clip seam gained a `view`, so the
  design system places a decoder surface it never has to understand.
- `CompanionArtChoice.still`: the approved picture, resolved at every tier and
  carried alongside a clip so there is always something under it.
- `CompanionController.artUrl`: a minted, race-safe URL for that picture.
- A rendering ladder in `_CompanionArt`: clip, then picture, then mood icon.
- `TopicPlayerPage` plays a topic that carries a real URL, and keeps the
  deterministic clock for the `fixture` topics that are all the catalog has.

## Rules kept

- Nothing plays unasked. Every playback starts from a learner tap.
- Reduced motion, sound off, and Classroom Mode each beat anything published.
- Every failure is a fallback: an expired URL, a dead link, a codec that will
  not open, or a platform with no plugin all end with a picture or an icon and
  a caption, never an error and never an empty frame.
- The watch-credit contract is untouched. The server still decides.

## Out of scope

- Art. One approved picture exists; MED-09 produces the pack.
- Local animation. `CompanionAssetTier.localAnimation` still resolves to a
  still; MED-10 implements the tier.
- Narration and clip coverage, which is MED-11.
- Sourcing real lesson video. Every topic is a `fixture` with a slug, and
  choosing a video provider is content administration.
