# MED-07 decisions

## Character motion over camera motion

The owner rejected MED-06's first composed clip because nothing in the picture
moved. Wan 2.2 image-to-video animates the approved art: Nori waves, blinks,
and breathes. The authored motion names (`hold`, `settle`, `driftIn`,
`pushIn`, `dip`) are kept so no clip row has to be rewritten, but they now
describe the character rather than a camera.

## The Space is the default; the composer is the fallback

`cinderholm/wan2-2-i2v-v3` is a public Hugging Face Space with no agreement
behind it. It can sleep, queue behind strangers, or vanish. json2video is
worse-looking but dependable and already paid for, so it stays as the one
place to fall rather than being deleted.

Fallback is a column on `generation_providers`, not a branch in the worker:
same kind, one hop, never itself. A chain would let a single bad row send a
request wandering; a cross-kind fallback would answer a clip with a recording.

## Not resumable, so no pending job

Measured against the live Space: disconnecting from the event stream kills
the render, and reconnecting to the same event id answers `error`. The
adapter therefore has no `generateOrPending`. Offering one would record a
`provider_job_id` that can never be collected. The worker holds the
connection up to a deadline (default 110s) and falls back if the Space does
not finish.

## Upload first; a signed URL is not enough

The Space refuses to fetch a remote picture. The adapter downloads the
approved art, uploads the bytes to the Space, then references the path it
hands back. Passing a signed URL as FileData fails with a bare error.

## `frame_multiplier` is a number

The published schema calls it a string. The Space rejects strings against
the choices `[16, 32, 64, 128]` and answers with `event: error` and no
message. Sending the integer 16 is what works. Regressing this costs an hour
to rediscover, so a Deno test pins it.

## Provider_id must stay honest after a fallback

The asset row names a provider at request time. When the primary is down the
bytes come from somewhere else, and a review queue that still shows the
provider we asked is a review queue that lies about what a reviewer is
looking at. `record_generated_asset_provider_swap` corrects the row and
leaves `fell_back_from` and `fallback_reason` in provenance.

## Cost is recorded as zero

A public Space bills nothing. Recording an estimate would make MED-02's
budget refuse clips that cost no money. json2video still charges when it is
the one that runs.

## What still cannot be animated

Animation composes only from approved art. Exactly one picture is approved
(`guide_greeting` 1:1). The other authored reactions have no art, and
Pollinations `sana` still cannot draw a mascot. This module builds and proves
the pipeline; coverage beyond greeting waits on an image provider that can
draw or on more curated uploads.
