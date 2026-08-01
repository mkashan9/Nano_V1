# MED-06 known issues

## Keys are set

Both provider keys were pasted into Edge Function secrets by the owner on
2026-08-01. Live Fish TTS and live json2video compose both answered. They are
not in git and must never be.

## The Learning Guide is cast

`guide_educational` is the default voice: Fish Educational Guide
(`2c408095b1294de896376eff6a638d90`), chosen by the owner from five candidates
against the authored greeting and quiz lines. ADR-0008 records why it is a
female teacher rather than the mascot speaking. `guide_fish_stock` stays
enabled but is no longer default; the stock recording of `greeting-2` was
rejected with that reason and re-recorded in the cast voice.

## json2video motion was judged fake

The owner rejected the composed `guide_greeting_shortClip` because a pan over a
still is not character animation. A live probe of
`cinderholm/wan2-2-i2v-v3` against the approved Nori art produced a 3.3-second
clip where Nori stays on model and genuinely waves. That work is MED-07 and
waits for MED-06 DONE; until then no reaction clip is published, and every
reaction keeps its local art.

## Cost figures are estimates

`VOICE_PROVIDER_COST_MICROS_PER_1K_CHARS` defaults to 15000 and
`VIDEO_COST_MICROS_PER_CLIP` defaults to 15000. Correct them once a real invoice
exists. The request ceilings (100 voice / 20 video per day) already stop a runaway.

## The image provider cannot draw

Pollinations serves exactly one model to callers without a token, `sana`, and it
is not good enough for companion art. Asked for a flat vector mascot it returns
a blur; asked for a cute character it returns a photograph of a child. Eleven
prompts were tried across three art directions and none produced anything
approvable. The owner rejected the first generated image on sight, and the fault
is the model rather than the wording.

Two ways out, and they are not exclusive:

- Pay for an image provider that can draw. That is a key, a purchase, and an
  owner decision, and the adapter would be small.
- Supply the picture by hand. MED-06 added that path
  (`register_curated_asset`), because the handbook's asset ladder starts at
  Tier 0 static art and static art is usually drawn rather than generated.

Until the first is done, `pollinations_image` stays the default and stays close
to useless for anything a child will look at.

## The companion picture is curated and approved

`guide_greeting_staticArt` is a hand-supplied picture registered through
`register_curated_asset` and approved. Learners can read it, and the compose
gate is open for `guide_greeting` in `1:1`. The earlier generated one stays
`rejected` as the record of why.

## The curated master lives outside the repo

Only the 512×512 JPEG that was uploaded exists in Supabase storage. The 1024×1024
master it was resized from is not in git. `assets/provenance/` is the obvious
home for it, but committing binaries is a decision the owner has not made, and
MED-01 put bundled companion art out of scope.

## Playback is admin_web only

The Moderation queue plays voice and video through the browser's own elements,
reached by a conditional import. Nothing else in Nano gained a player: the
student and teacher apps still show captions and local art, and attaching a
player there is still MED-03 and MED-04 work that has not been done.

The widget tests run on the VM, so they resolve the stub and exercise the
metadata fallback rather than the players. Playback itself was verified by
building for web and opening the queue.

## Deno was never on the PATH

Adapter tests for MED-03 and MED-04 had been written but never executed. This
module installed Deno into a temp directory and ran all 56; they all pass. The
install is not committed and is not on the PATH for future shells.
