# MED-08 — Known issues

## One picture exists, so most reactions still show an icon

`guide_greeting_staticArt` is the only approved image. Every other reaction
falls through to the mood icon exactly as before. The rendering path is done;
the art is MED-09.

## The local animation tier is still a still

`CompanionAssetTier.localAnimation` resolves to static art because nothing
implements Tier 1 yet. Greeting asks for it and gets a picture. MED-10.

## Only one line is recorded

`narration_greeting-2` in English. Urdu narration and every other moment are
caption-only, which is correct behaviour and thin coverage. MED-11.

## No lesson video anywhere

Every topic is a `fixture`. The decoder path is built and tested but cannot be
exercised against real content until a video provider is chosen and topics
carry real references. Not a media module problem.

## `Image.network` has no disk cache

The signed URL is cached in memory by the asset cache and Flutter caches the
decoded image, but a cold start re-fetches. Acceptable at 25 KB per picture;
worth revisiting in MED-09 when there are 25 of them and a bundled offline
floor exists.

## Clip playback is unverified on a device

Widget tests cover the wiring with recording doubles, and the codec path cannot
run in a widget test. The owner manual test is what confirms a real MP4 decodes
and plays silently on a real browser or handset.
