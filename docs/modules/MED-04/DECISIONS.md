# MED-04 decisions

## Reusable means mode+mood, not screen

A clip authored for `celebration_celebration` is used wherever Celebration Nori
celebrates. Binding clips to screens would force re-authoring the same motion
for home, quiz results, and progress.

## Silent, one language

A clip has no words. Splitting by language would pay twice for identical frames.
Narration (MED-03) is the opposite: language is identity.

## Aspect ratio is authoring, not rendering

A square inline clip and a tall story-card clip are different jobs. Unauthored
shapes are refused (`NM009`) rather than stretched.

## Claims expire

Image generation finishes in seconds; video does not. A claim without an expiry
leaves a dead `generating` row that the reuse index treats as a finished answer,
making the slot unaskable. Twenty minutes for video, with a three-attempt
ceiling, is the recovery contract.

## Player as a seam, play as a tap

`NanoClipPlayer` mirrors `NanoVoicePlayer`. No plugin yet; production attaches
none. When a clip exists and a player is attached, the art shows a play badge
and only taps start playback — never autoplay, never over reduced motion.
