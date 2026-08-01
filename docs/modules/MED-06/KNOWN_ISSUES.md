# MED-06 known issues

## Keys are validated but not set

Both provider keys were validated live against their APIs on 2026-08-01 and then
cleared from the shell. They are not Edge Function secrets yet. Until the owner
pastes them in Studio, every voice and every clip fails closed with
`PROVIDER_UNCONFIGURED`, which is the correct undeployed state: every caption
and every reaction keeps its local art.

## No Fish reference_id yet

The Learning Guide speaks in Fish's stock voice. Picking a specific
`reference_id` is a new `narration_voices` row (the voice id is part of the
reuse hash), not an edit of `guide_fish_stock`.

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

## The companion picture is curated, not generated

`guide_greeting_staticArt` now holds a hand-supplied picture registered through
`register_curated_asset`, sitting `ready` / `unreviewed`. The earlier generated
one is `rejected` and stays in the table as the record of why. A clip of
`guide_greeting` still refuses with `NM011` until a reviewer approves the new
picture in `1:1`. That is the gate working, not a bug.

## The curated master lives outside the repo

Only the 512×512 JPEG that was uploaded exists in Supabase storage. The 1024×1024
master it was resized from is not in git. `assets/provenance/` is the obvious
home for it, but committing binaries is a decision the owner has not made, and
MED-01 put bundled companion art out of scope.

## Deno was never on the PATH

Adapter tests for MED-03 and MED-04 had been written but never executed. This
module installed Deno into a temp directory and ran all 56; they all pass. The
install is not committed and is not on the PATH for future shells.
